package v5

import (
	"github.com/cosmos/cosmos-sdk/client"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/module"
	genutiltypes "github.com/cosmos/cosmos-sdk/x/genutil/types"
	upgradetypes "github.com/cosmos/cosmos-sdk/x/upgrade/types"

	"github.com/tharsis/evmos/v4/types"

	bankkeeper "github.com/cosmos/cosmos-sdk/x/bank/keeper"
	banktypes "github.com/cosmos/cosmos-sdk/x/bank/types"
	evmtypes "github.com/tharsis/ethermint/x/evm/types"
	feemarketv011 "github.com/tharsis/ethermint/x/feemarket/migrations/v011"
	feemarketv10types "github.com/tharsis/ethermint/x/feemarket/migrations/v10/types"
	feemarkettypes "github.com/tharsis/ethermint/x/feemarket/types"
)

// CreateUpgradeHandler creates an SDK upgrade handler for v4
func CreateUpgradeHandler(
	mm *module.Manager,
	configurator module.Configurator,
	bankKeeper bankkeeper.Keeper,
) upgradetypes.UpgradeHandler {
	return func(ctx sdk.Context, _ upgradetypes.Plan, vm module.VersionMap) (module.VersionMap, error) {
		// Refs:
		// - https://docs.cosmos.network/master/building-modules/upgrade.html#registering-migrations
		// - https://docs.cosmos.network/master/migrations/chain-upgrade-guide-044.html#chain-upgrade

		if types.IsTestnet(ctx.ChainID()) {
			// Add atevmos
			AddAtevmosMetadata(ctx, bankKeeper)

		}

		vm[evmtypes.ModuleName] = 2
		vm[feemarkettypes.ModuleName] = 3

		return mm.RunMigrations(ctx, configurator, vm)
	}
}

// MigrateGenesis migrates exported state from v2 to v3 genesis state.
// It performs a no-op if the migration errors.
func MigrateGenesis(appState genutiltypes.AppMap, clientCtx client.Context) genutiltypes.AppMap {
	// Migrate x/feemarket.
	if appState[feemarkettypes.ModuleName] == nil {
		return appState
	}

	// unmarshal relative source genesis application state
	var oldFeeMarketState feemarketv10types.GenesisState
	if err := clientCtx.Codec.UnmarshalJSON(appState[feemarkettypes.ModuleName], &oldFeeMarketState); err != nil {
		return appState
	}

	// delete deprecated x/feemarket genesis state
	delete(appState, feemarkettypes.ModuleName)

	// Migrate relative source genesis application state and marshal it into
	// the respective key.
	newFeeMarketState := feemarketv011.MigrateJSON(oldFeeMarketState)

	feeMarketBz, err := clientCtx.Codec.MarshalJSON(&newFeeMarketState)
	if err != nil {
		return appState
	}

	appState[feemarkettypes.ModuleName] = feeMarketBz

	return appState
}

func AddAtevmosMetadata(ctx sdk.Context, bankKeeper bankkeeper.Keeper) {
	atevmos := banktypes.Metadata{
		Base:        "atevmos",
		Display:     "tevmos",
		Name:        "Testnet Evmos",
		Symbol:      "TEVMOS",
		Description: "EVM, staking and governance denom of Testnet Evmos",
		DenomUnits: []*banktypes.DenomUnit{
			{
				Denom:    "atevmos",
				Exponent: 0,
				Aliases:  []string{"atto testnet evmos"},
			},
		},
	}

	bankKeeper.SetDenomMetaData(ctx, atevmos)
}
