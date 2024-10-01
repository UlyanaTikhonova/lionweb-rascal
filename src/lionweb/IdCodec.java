package lionweb;

import java.nio.charset.Charset;
import java.util.Base64;

import io.usethesource.vallang.IString;
import io.usethesource.vallang.IValueFactory;
import io.usethesource.vallang.IBool;

public class IdCodec {
    protected final IValueFactory values;

    public IdCodec(IValueFactory values){
        super();
        this.values = values;
    }

    public IString toBase64url(IString inputString, IString charsetName, IBool includePadding) {
        Base64.Encoder encoder = Base64.getUrlEncoder();
        if (!includePadding.getValue()) {
            encoder = encoder.withoutPadding();
        }
        String encodedString = new String(encoder.encode(inputString.getValue().getBytes(Charset.forName(charsetName.getValue()))));
        return values.string(encodedString);
    }

    public IString fromBase64url(IString inputString, IString charsetName) {
        Base64.Decoder decoder = Base64.getUrlDecoder();
        String decodedString = new String(decoder.decode(inputString.getValue()), Charset.forName(charsetName.getValue()));
        return values.string(decodedString);
    }
}
