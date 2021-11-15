package encoding

import (
	"fmt"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/codec"
	amino "github.com/cosmos/cosmos-sdk/codec"
	codectypes "github.com/cosmos/cosmos-sdk/codec/types"
	cryptotypes "github.com/cosmos/cosmos-sdk/crypto/types"
	"github.com/cosmos/cosmos-sdk/simapp/params"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/module"
	"github.com/cosmos/cosmos-sdk/types/tx/signing"
	signingtypes "github.com/cosmos/cosmos-sdk/types/tx/signing"
	"github.com/cosmos/cosmos-sdk/x/auth/legacy/legacytx"
	authsigning "github.com/cosmos/cosmos-sdk/x/auth/signing"
	"github.com/cosmos/cosmos-sdk/x/auth/tx"

	enccodec "github.com/tharsis/ethermint/encoding/codec"
)

// MakeConfig creates an EncodingConfig for testing
func MakeConfig(mb module.BasicManager) params.EncodingConfig {
	cdc := amino.NewLegacyAmino()
	interfaceRegistry := codectypes.NewInterfaceRegistry()
	marshaler := amino.NewProtoCodec(interfaceRegistry)

	encodingConfig := params.EncodingConfig{
		InterfaceRegistry: interfaceRegistry,
		Marshaler:         marshaler,
		TxConfig:          NewTxConfig(marshaler, tx.DefaultSignModes),
		Amino:             cdc,
	}

	enccodec.RegisterLegacyAminoCodec(encodingConfig.Amino)
	mb.RegisterLegacyAminoCodec(encodingConfig.Amino)
	enccodec.RegisterInterfaces(encodingConfig.InterfaceRegistry)
	mb.RegisterInterfaces(encodingConfig.InterfaceRegistry)
	return encodingConfig
}

// NewTxConfig returns a new protobuf TxConfig using the provided ProtoCodec and sign modes. The
// first enabled sign mode will become the default sign mode.
func NewTxConfig(protoCodec codec.ProtoCodecMarshaler, enabledSignModes []signingtypes.SignMode) client.TxConfig {
	return &config{
		handler:     makeSignModeHandler(enabledSignModes),
		decoder:     tx.DefaultTxDecoder(protoCodec),
		encoder:     tx.DefaultTxEncoder(),
		jsonDecoder: tx.DefaultJSONTxDecoder(protoCodec),
		jsonEncoder: tx.DefaultJSONTxEncoder(protoCodec),
		protoCodec:  protoCodec,
	}
}

// makeSignModeHandler returns the default protobuf SignModeHandler supporting
// SIGN_MODE_DIRECT and SIGN_MODE_LEGACY_AMINO_JSON.
func makeSignModeHandler(modes []signingtypes.SignMode) authsigning.SignModeHandler {
	if len(modes) < 1 {
		panic(fmt.Errorf("no sign modes enabled"))
	}

	handlers := make([]authsigning.SignModeHandler, len(modes))

	for i, mode := range modes {
		switch mode {
		case signingtypes.SignMode_SIGN_MODE_DIRECT:
			handlers[i] = signModeDirectHandler{}
		case signingtypes.SignMode_SIGN_MODE_LEGACY_AMINO_JSON:
			handlers[i] = legacytx.NewStdTxSignModeHandler()
		default:
			panic(fmt.Errorf("unsupported sign mode %+v", mode))
		}
	}

	return authsigning.NewSignModeHandlerMap(
		signingtypes.SignMode_SIGN_MODE_DIRECT,
		handlers,
	)
}

var (
	_ client.TxEncodingConfig = &config{}
	_ client.TxConfig         = &config{}
)

type config struct {
	handler     authsigning.SignModeHandler
	decoder     sdk.TxDecoder
	encoder     sdk.TxEncoder
	jsonDecoder sdk.TxDecoder
	jsonEncoder sdk.TxEncoder
	protoCodec  codec.ProtoCodecMarshaler
}

func (c config) NewTxBuilder() client.TxBuilder {
	return nil
}

func (c config) WrapTxBuilder(newTx sdk.Tx) (client.TxBuilder, error) {
	return nil, nil
}

func (c config) SignModeHandler() authsigning.SignModeHandler {
	return c.handler
}

func (c config) TxEncoder() sdk.TxEncoder {
	return c.encoder
}

func (c config) TxDecoder() sdk.TxDecoder {
	return c.decoder
}

func (c config) TxJSONEncoder() sdk.TxEncoder {
	return c.jsonEncoder
}

func (c config) TxJSONDecoder() sdk.TxDecoder {
	return c.jsonDecoder
}

func (g config) MarshalSignatureJSON(sigs []signing.SignatureV2) ([]byte, error) {
	descs := make([]*signing.SignatureDescriptor, len(sigs))

	for i, sig := range sigs {
		descData := signing.SignatureDataToProto(sig.Data)
		any, err := codectypes.NewAnyWithValue(sig.PubKey)
		if err != nil {
			return nil, err
		}

		descs[i] = &signing.SignatureDescriptor{
			PublicKey: any,
			Data:      descData,
			Sequence:  sig.Sequence,
		}
	}

	toJSON := &signing.SignatureDescriptors{Signatures: descs}

	return codec.ProtoMarshalJSON(toJSON, nil)
}

func (g config) UnmarshalSignatureJSON(bz []byte) ([]signing.SignatureV2, error) {
	var sigDescs signing.SignatureDescriptors
	err := g.protoCodec.UnmarshalJSON(bz, &sigDescs)
	if err != nil {
		return nil, err
	}

	sigs := make([]signing.SignatureV2, len(sigDescs.Signatures))
	for i, desc := range sigDescs.Signatures {
		pubKey, _ := desc.PublicKey.GetCachedValue().(cryptotypes.PubKey)

		data := signing.SignatureDataFromProto(desc.Data)

		sigs[i] = signing.SignatureV2{
			PubKey:   pubKey,
			Data:     data,
			Sequence: desc.Sequence,
		}
	}

	return sigs, nil
}
