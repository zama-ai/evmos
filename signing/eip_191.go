package signing

import (
	"bytes"
	"encoding/json"
	"fmt"
	"strconv"

	sdk "github.com/cosmos/cosmos-sdk/types"
	sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"
	signingtypes "github.com/cosmos/cosmos-sdk/types/tx/signing"
	"github.com/cosmos/cosmos-sdk/x/auth/ante"
	"github.com/cosmos/cosmos-sdk/x/auth/legacy/legacytx"
	authsigning "github.com/cosmos/cosmos-sdk/x/auth/signing"
)

const (
	// SignModeEIP191LegacyJSON is a signing mode that is designed to verify
	// signatures created using the Ethereum Signed Data standard specified in
	// EIP 191 (https://eips.ethereum.org/EIPS/eip-191)
	// It will use the LEGACY_AMINO_JSON format and then wrap it in the EIP 191 standard.
	// In particular, this hex encodes the JSON string and then prepends it with
	// "\x19Ethereum Signed Message:\n" + len(message)
	SignModeEIP191LegacyJSON = 191

	EIP191MessagePrefix = "\x19Ethereum Signed Message:\n"
)

var DefaultSignModes = []signingtypes.SignMode{
	signingtypes.SignMode_SIGN_MODE_DIRECT,
	signingtypes.SignMode_SIGN_MODE_LEGACY_AMINO_JSON,
	SignModeEIP191LegacyJSON,
}

var _ authsigning.SignModeHandler = signModeEIP191LegacyJSONHandler{}

// signModeEIP191LegacyJSONHandler defines the SIGN_MODE_EIP191_LEGACY_JSON
// SignModeHandler.
type signModeEIP191LegacyJSONHandler struct{}

func (s signModeEIP191LegacyJSONHandler) DefaultMode() signingtypes.SignMode {
	return SignModeEIP191LegacyJSON
}

func (s signModeEIP191LegacyJSONHandler) Modes() []signingtypes.SignMode {
	return []signingtypes.SignMode{SignModeEIP191LegacyJSON}
}

func (s signModeEIP191LegacyJSONHandler) GetSignBytes(mode signingtypes.SignMode, data authsigning.SignerData, tx sdk.Tx) ([]byte, error) {
	if mode != SignModeEIP191LegacyJSON {
		return nil, fmt.Errorf("expected %d, got %s", SignModeEIP191LegacyJSON, mode)
	}

	extTx, ok := tx.(ante.HasExtensionOptionsTx)
	if !ok {
		return nil, fmt.Errorf("can only handle a protobuf Tx, got %T", tx)
	}

	if len(extTx.GetExtensionOptions()) != 0 || len(extTx.GetNonCriticalExtensionOptions()) != 0 {
		return nil, sdkerrors.Wrap(sdkerrors.ErrInvalidRequest, "SignMode_SIGN_MODE_EIP191_LEGACY_JSON does not support protobuf extension options.")
	}

	authsigTx, ok := tx.(authsigning.Tx)
	if !ok {
		return nil, fmt.Errorf("can only handle a protobuf Tx, got %T", tx)
	}

	aminoJSONBz := legacytx.StdSignBytes(
		data.ChainID, data.AccountNumber, data.Sequence, authsigTx.GetTimeoutHeight(),
		legacytx.StdFee{Amount: authsigTx.GetFee(), Gas: authsigTx.GetGas()},
		tx.GetMsgs(), authsigTx.GetMemo(),
	)

	var out bytes.Buffer
	if err := json.Indent(&out, aminoJSONBz, "", "  "); err != nil {
		return nil, err
	}

	bz := append(
		[]byte(EIP191MessagePrefix),
		[]byte(strconv.Itoa(len(out.Bytes())))...,
	)

	bz = append(bz, out.Bytes()...)
	// bz = append(bz, aminoJSONBz...)

	return bz, nil
}
