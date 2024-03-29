package Crypt::PK::ECC;

use strict;
use warnings;

use Exporter 'import';
our %EXPORT_TAGS = ( all => [qw( ecc_encrypt ecc_decrypt ecc_sign_message ecc_verify_message ecc_sign_hash ecc_verify_hash ecc_shared_secret )] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

use CryptX;
use Crypt::PK;
use Crypt::Digest 'digest_data';
use Carp;
use MIME::Base64 qw(encode_base64 decode_base64);

our %curve = (
        ### http://www.ecc-brainpool.org/download/Domain-parameters.pdf (v1.0 19.10.2005)
        brainpoolP160r1 => {
            prime    => "E95E4A5F737059DC60DFC7AD95B3D8139515620F",
            A        => "340E7BE2A280EB74E2BE61BADA745D97E8F7C300",
            B        => "1E589A8595423412134FAA2DBDEC95C8D8675E58",
            Gx       => "BED5AF16EA3F6A4F62938C4631EB5AF7BDBCDBC3",
            Gy       => "1667CB477A1A8EC338F94741669C976316DA6321",
            order    => "E95E4A5F737059DC60DF5991D45029409E60FC09",
            cofactor => 1,
        },
        brainpoolP192r1 => {
            prime    => "C302F41D932A36CDA7A3463093D18DB78FCE476DE1A86297",
            A        => "6A91174076B1E0E19C39C031FE8685C1CAE040E5C69A28EF",
            B        => "469A28EF7C28CCA3DC721D044F4496BCCA7EF4146FBF25C9",
            Gx       => "C0A0647EAAB6A48753B033C56CB0F0900A2F5C4853375FD6",
            Gy       => "14B690866ABD5BB88B5F4828C1490002E6773FA2FA299B8F",
            order    => "C302F41D932A36CDA7A3462F9E9E916B5BE8F1029AC4ACC1",
            cofactor => 1,
        },
        brainpoolP224r1 => {
            prime    => "D7C134AA264366862A18302575D1D787B09F075797DA89F57EC8C0FF",
            A        => "68A5E62CA9CE6C1C299803A6C1530B514E182AD8B0042A59CAD29F43",
            B        => "2580F63CCFE44138870713B1A92369E33E2135D266DBB372386C400B",
            Gx       => "0D9029AD2C7E5CF4340823B2A87DC68C9E4CE3174C1E6EFDEE12C07D",
            Gy       => "58AA56F772C0726F24C6B89E4ECDAC24354B9E99CAA3F6D3761402CD",
            order    => "D7C134AA264366862A18302575D0FB98D116BC4B6DDEBCA3A5A7939F",
            cofactor => 1,
        },
        brainpoolP256r1 => {
            prime    => "A9FB57DBA1EEA9BC3E660A909D838D726E3BF623D52620282013481D1F6E5377",
            A        => "7D5A0975FC2C3057EEF67530417AFFE7FB8055C126DC5C6CE94A4B44F330B5D9",
            B        => "26DC5C6CE94A4B44F330B5D9BBD77CBF958416295CF7E1CE6BCCDC18FF8C07B6",
            Gx       => "8BD2AEB9CB7E57CB2C4B482FFC81B7AFB9DE27E1E3BD23C23A4453BD9ACE3262",
            Gy       => "547EF835C3DAC4FD97F8461A14611DC9C27745132DED8E545C1D54C72F046997",
            order    => "A9FB57DBA1EEA9BC3E660A909D838D718C397AA3B561A6F7901E0E82974856A7",
            cofactor => 1,
        },
        brainpoolP320r1 => {
            prime    => "D35E472036BC4FB7E13C785ED201E065F98FCFA6F6F40DEF4F92B9EC7893EC28FCD412B1F1B32E27",
            A        => "3EE30B568FBAB0F883CCEBD46D3F3BB8A2A73513F5EB79DA66190EB085FFA9F492F375A97D860EB4",
            B        => "520883949DFDBC42D3AD198640688A6FE13F41349554B49ACC31DCCD884539816F5EB4AC8FB1F1A6",
            Gx       => "43BD7E9AFB53D8B85289BCC48EE5BFE6F20137D10A087EB6E7871E2A10A599C710AF8D0D39E20611",
            Gy       => "14FDD05545EC1CC8AB4093247F77275E0743FFED117182EAA9C77877AAAC6AC7D35245D1692E8EE1",
            order    => "D35E472036BC4FB7E13C785ED201E065F98FCFA5B68F12A32D482EC7EE8658E98691555B44C59311",
            cofactor => 1,
        },
        brainpoolP384r1 => {
            prime    => "8CB91E82A3386D280F5D6F7E50E641DF152F7109ED5456B412B1DA197FB71123ACD3A729901D1A71874700133107EC53",
            A        => "7BC382C63D8C150C3C72080ACE05AFA0C2BEA28E4FB22787139165EFBA91F90F8AA5814A503AD4EB04A8C7DD22CE2826",
            B        => "04A8C7DD22CE28268B39B55416F0447C2FB77DE107DCD2A62E880EA53EEB62D57CB4390295DBC9943AB78696FA504C11",
            Gx       => "1D1C64F068CF45FFA2A63A81B7C13F6B8847A3E77EF14FE3DB7FCAFE0CBD10E8E826E03436D646AAEF87B2E247D4AF1E",
            Gy       => "8ABE1D7520F9C2A45CB1EB8E95CFD55262B70B29FEEC5864E19C054FF99129280E4646217791811142820341263C5315",
            order    => "8CB91E82A3386D280F5D6F7E50E641DF152F7109ED5456B31F166E6CAC0425A7CF3AB6AF6B7FC3103B883202E9046565",
            cofactor => 1,
        },
        brainpoolP512r1 => {
            prime    => "AADD9DB8DBE9C48B3FD4E6AE33C9FC07CB308DB3B3C9D20ED6639CCA703308717D4D9B009BC66842AECDA12AE6A380E62881FF2F2D82C68528AA6056583A48F3",
            A        => "7830A3318B603B89E2327145AC234CC594CBDD8D3DF91610A83441CAEA9863BC2DED5D5AA8253AA10A2EF1C98B9AC8B57F1117A72BF2C7B9E7C1AC4D77FC94CA",
            B        => "3DF91610A83441CAEA9863BC2DED5D5AA8253AA10A2EF1C98B9AC8B57F1117A72BF2C7B9E7C1AC4D77FC94CADC083E67984050B75EBAE5DD2809BD638016F723",
            Gx       => "81AEE4BDD82ED9645A21322E9C4C6A9385ED9F70B5D916C1B43B62EEF4D0098EFF3B1F78E2D0D48D50D1687B93B97D5F7C6D5047406A5E688B352209BCB9F822",
            Gy       => "7DDE385D566332ECC0EABFA9CF7822FDF209F70024A57B1AA000C55B881F8111B2DCDE494A5F485E5BCA4BD88A2763AED1CA2B2FA8F0540678CD1E0F3AD80892",
            order    => "AADD9DB8DBE9C48B3FD4E6AE33C9FC07CB308DB3B3C9D20ED6639CCA70330870553E5C414CA92619418661197FAC10471DB1D381085DDADDB58796829CA90069",
            cofactor => 1,
        },
        ### http://www.secg.org/collateral/sec2_final.pdf (September 20, 2000 - Version 1.0)
        secp112r1 => {
            prime    => "DB7C2ABF62E35E668076BEAD208B",
            A        => "DB7C2ABF62E35E668076BEAD2088",
            B        => "659EF8BA043916EEDE8911702B22",
            Gx       => "09487239995A5EE76B55F9C2F098",
            Gy       => "A89CE5AF8724C0A23E0E0FF77500",
            order    => "DB7C2ABF62E35E7628DFAC6561C5",
            cofactor => 1,
        },
        secp112r2 => {
            prime    => "DB7C2ABF62E35E668076BEAD208B",
            A        => "6127C24C05F38A0AAAF65C0EF02C",
            B        => "51DEF1815DB5ED74FCC34C85D709",
            Gx       => "4BA30AB5E892B4E1649DD0928643",
            Gy       => "ADCD46F5882E3747DEF36E956E97",
            order    => "36DF0AAFD8B8D7597CA10520D04B",
            cofactor => 4,
        },
        secp128r1 => {
            prime    => "FFFFFFFDFFFFFFFFFFFFFFFFFFFFFFFF",
            A        => "FFFFFFFDFFFFFFFFFFFFFFFFFFFFFFFC",
            B        => "E87579C11079F43DD824993C2CEE5ED3",
            Gx       => "161FF7528B899B2D0C28607CA52C5B86",
            Gy       => "CF5AC8395BAFEB13C02DA292DDED7A83",
            order    => "FFFFFFFE0000000075A30D1B9038A115",
            cofactor => 1,
        },
        secp128r2 => {
            prime    => "FFFFFFFDFFFFFFFFFFFFFFFFFFFFFFFF",
            A        => "D6031998D1B3BBFEBF59CC9BBFF9AEE1",
            B        => "5EEEFCA380D02919DC2C6558BB6D8A5D",
            Gx       => "7B6AA5D85E572983E6FB32A7CDEBC140",
            Gy       => "27B6916A894D3AEE7106FE805FC34B44",
            order    => "3FFFFFFF7FFFFFFFBE0024720613B5A3",
            cofactor => 4,
        },
        secp160k1 => {
            prime    => "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFAC73",
            A        => "0000000000000000000000000000000000000000",
            B        => "0000000000000000000000000000000000000007",
            Gx       => "3B4C382CE37AA192A4019E763036F4F5DD4D7EBB",
            Gy       => "938CF935318FDCED6BC28286531733C3F03C4FEE",
            order    => "0100000000000000000001B8FA16DFAB9ACA16B6B3",
            cofactor => 1,
        },
        secp160r1 => {
            prime    => "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFF",
            A        => "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFC",
            B        => "1C97BEFC54BD7A8B65ACF89F81D4D4ADC565FA45",
            Gx       => "4A96B5688EF573284664698968C38BB913CBFC82",
            Gy       => "23A628553168947D59DCC912042351377AC5FB32",
            order    => "0100000000000000000001F4C8F927AED3CA752257",
            cofactor => 1,
        },
        secp160r2 => {
            prime    => "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFAC73",
            A        => "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFAC70",
            B        => "B4E134D3FB59EB8BAB57274904664D5AF50388BA",
            Gx       => "52DCB034293A117E1F4FF11B30F7199D3144CE6D",
            Gy       => "FEAFFEF2E331F296E071FA0DF9982CFEA7D43F2E",
            order    => "0100000000000000000000351EE786A818F3A1A16B",
            cofactor => 1,
        },
        secp192k1 => {
            prime    => "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFEE37",
            A        => "000000000000000000000000000000000000000000000000",
            B        => "000000000000000000000000000000000000000000000003",
            Gx       => "DB4FF10EC057E9AE26B07D0280B7F4341DA5D1B1EAE06C7D",
            Gy       => "9B2F2F6D9C5628A7844163D015BE86344082AA88D95E2F9D",
            order    => "FFFFFFFFFFFFFFFFFFFFFFFE26F2FC170F69466A74DEFD8D",
            cofactor => 1,
        },
        secp192r1 => {
            prime    => "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFF",
            A        => "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFC",
            B        => "64210519E59C80E70FA7E9AB72243049FEB8DEECC146B9B1",
            Gx       => "188DA80EB03090F67CBF20EB43A18800F4FF0AFD82FF1012",
            Gy       => "07192B95FFC8DA78631011ED6B24CDD573F977A11E794811",
            order    => "FFFFFFFFFFFFFFFFFFFFFFFF99DEF836146BC9B1B4D22831",
            cofactor => 1,
        },
        secp224k1 => {
            prime    => "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFE56D",
            A        => "00000000000000000000000000000000000000000000000000000000",
            B        => "00000000000000000000000000000000000000000000000000000005",
            Gx       => "A1455B334DF099DF30FC28A169A467E9E47075A90F7E650EB6B7A45C",
            Gy       => "7E089FED7FBA344282CAFBD6F7E319F7C0B0BD59E2CA4BDB556D61A5",
            order    => "010000000000000000000000000001DCE8D2EC6184CAF0A971769FB1F7",
            cofactor => 1,
        },
        secp224r1 => {
            prime    => "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000001",
            A        => "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFE",
            B        => "B4050A850C04B3ABF54132565044B0B7D7BFD8BA270B39432355FFB4",
            Gx       => "B70E0CBD6BB4BF7F321390B94A03C1D356C21122343280D6115C1D21",
            Gy       => "BD376388B5F723FB4C22DFE6CD4375A05A07476444D5819985007E34",
            order    => "FFFFFFFFFFFFFFFFFFFFFFFFFFFF16A2E0B8F03E13DD29455C5C2A3D",
            cofactor => 1,
        },
        secp256k1 => {
            prime    => "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F",
            A        => "0000000000000000000000000000000000000000000000000000000000000000",
            B        => "0000000000000000000000000000000000000000000000000000000000000007",
            Gx       => "79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798",
            Gy       => "483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8",
            order    => "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141",
            cofactor => 1,
        },
        secp256r1 => {
            prime    => "FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF",
            A        => "FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC",
            B        => "5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B",
            Gx       => "6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296",
            Gy       => "4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5",
            order    => "FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551",
            cofactor => 1,
        },
        secp384r1 => {
            prime    => "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFF0000000000000000FFFFFFFF",
            A        => "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFF0000000000000000FFFFFFFC",
            B        => "B3312FA7E23EE7E4988E056BE3F82D19181D9C6EFE8141120314088F5013875AC656398D8A2ED19D2A85C8EDD3EC2AEF",
            Gx       => "AA87CA22BE8B05378EB1C71EF320AD746E1D3B628BA79B9859F741E082542A385502F25DBF55296C3A545E3872760AB7",
            Gy       => "3617DE4A96262C6F5D9E98BF9292DC29F8F41DBD289A147CE9DA3113B5F0B8C00A60B1CE1D7E819D7A431D7C90EA0E5F",
            order    => "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7634D81F4372DDF581A0DB248B0A77AECEC196ACCC52973",
            cofactor => 1,
        },
        secp521r1 => {
            prime    => "01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
            A        => "01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC",
            B        => "0051953EB9618E1C9A1F929A21A0B68540EEA2DA725B99B315F3B8B489918EF109E156193951EC7E937B1652C0BD3BB1BF073573DF883D2C34F1EF451FD46B503F00",
            Gx       => "00C6858E06B70404E9CD9E3ECB662395B4429C648139053FB521F828AF606B4D3DBAA14B5E77EFE75928FE1DC127A2FFA8DE3348B3C1856A429BF97E7E31C2E5BD66",
            Gy       => "011839296A789A3BC0045C8A5FB42C7D1BD998F54449579B446817AFBD17273E662C97EE72995EF42640C550B9013FAD0761353C7086A272C24088BE94769FD16650",
            order    => "01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFA51868783BF2F966B7FCC0148F709A5D03BB5C9B8899C47AEBB6FB71E91386409",
            cofactor => 1
         },
         ### http://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.186-4.pdf (July 2013)
        nistp192 => {
            prime    => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFF',
            A        => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFC',
            B        => '64210519E59C80E70FA7E9AB72243049FEB8DEECC146B9B1',
            Gx       => '188DA80EB03090F67CBF20EB43A18800F4FF0AFD82FF1012',
            Gy       => '07192B95FFC8DA78631011ED6B24CDD573F977A11E794811',
            order    => 'FFFFFFFFFFFFFFFFFFFFFFFF99DEF836146BC9B1B4D22831',
            cofactor => 1,
        },
        nistp224 => {
            prime    => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000001',
            A        => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFE',
            B        => 'B4050A850C04B3ABF54132565044B0B7D7BFD8BA270B39432355FFB4',
            Gx       => 'B70E0CBD6BB4BF7F321390B94A03C1D356C21122343280D6115C1D21',
            Gy       => 'BD376388B5F723FB4C22DFE6CD4375A05A07476444D5819985007E34',
            order    => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFF16A2E0B8F03E13DD29455C5C2A3D',
            cofactor => 1,
        },
        nistp256 => {
            prime    => 'FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF',
            A        => 'FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC',
            B        => '5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B',
            Gx       => '6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296',
            Gy       => '4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5',
            order    => 'FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551',
            cofactor => 1,
        },
        nistp384 => {
            prime    => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFF0000000000000000FFFFFFFF',
            A        => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFF0000000000000000FFFFFFFC',
            B        => 'B3312FA7E23EE7E4988E056BE3F82D19181D9C6EFE8141120314088F5013875AC656398D8A2ED19D2A85C8EDD3EC2AEF',
            Gx       => 'AA87CA22BE8B05378EB1C71EF320AD746E1D3B628BA79B9859F741E082542A385502F25DBF55296C3A545E3872760AB7',
            Gy       => '3617DE4A96262C6F5D9E98BF9292DC29F8F41DBD289A147CE9DA3113B5F0B8C00A60B1CE1D7E819D7A431D7C90EA0E5F',
            order    => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7634D81F4372DDF581A0DB248B0A77AECEC196ACCC52973',
            cofactor => 1,
        },
        nistp521 => {
            prime    => '1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF',
            A        => '1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC',
            B        => '051953EB9618E1C9A1F929A21A0B68540EEA2DA725B99B315F3B8B489918EF109E156193951EC7E937B1652C0BD3BB1BF073573DF883D2C34F1EF451FD46B503F00',
            Gx       => '0C6858E06B70404E9CD9E3ECB662395B4429C648139053FB521F828AF606B4D3DBAA14B5E77EFE75928FE1DC127A2FFA8DE3348B3C1856A429BF97E7E31C2E5BD66',
            Gy       => '11839296A789A3BC0045C8A5FB42C7D1BD998F54449579B446817AFBD17273E662C97EE72995EF42640C550B9013FAD0761353C7086A272C24088BE94769FD16650',
            order    => '1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFA51868783BF2F966B7FCC0148F709A5D03BB5C9B8899C47AEBB6FB71E91386409',
            cofactor => 1,
        },
        ### ANS X9.62 elliptic curves - http://www.flexiprovider.de/CurvesGfpX962.html
        prime192v1 => {
            prime    => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFF',
            A        => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFC',
            B        => '64210519E59C80E70FA7E9AB72243049FEB8DEECC146B9B1',
            Gx       => '188DA80EB03090F67CBF20EB43A18800F4FF0AFD82FF1012',
            Gy       => '07192B95FFC8DA78631011ED6B24CDD573F977A11E794811',
            order    => 'FFFFFFFFFFFFFFFFFFFFFFFF99DEF836146BC9B1B4D22831',
            cofactor => 1,
        },
        prime192v2 => {
            prime    => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFF',
            A        => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFC',
            B        => 'CC22D6DFB95C6B25E49C0D6364A4E5980C393AA21668D953',
            Gx       => 'EEA2BAE7E1497842F2DE7769CFE9C989C072AD696F48034A',
            Gy       => '6574D11D69B6EC7A672BB82A083DF2F2B0847DE970B2DE15',
            order    => 'FFFFFFFFFFFFFFFFFFFFFFFE5FB1A724DC80418648D8DD31',
            cofactor => 1
        },
        prime192v3 => {
            prime    => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFF',
            A        => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFC',
            B        => '22123DC2395A05CAA7423DAECCC94760A7D462256BD56916',
            Gx       => '7D29778100C65A1DA1783716588DCE2B8B4AEE8E228F1896',
            Gy       => '38A90F22637337334B49DCB66A6DC8F9978ACA7648A943B0',
            order    => 'FFFFFFFFFFFFFFFFFFFFFFFF7A62D031C83F4294F640EC13',
            cofactor => 1,
        },
        prime239v1 => {
            prime    => '7FFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFF8000000000007FFFFFFFFFFF',
            A        => '7FFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFF8000000000007FFFFFFFFFFC',
            B        => '6B016C3BDCF18941D0D654921475CA71A9DB2FB27D1D37796185C2942C0A',
            Gx       => '0FFA963CDCA8816CCC33B8642BEDF905C3D358573D3F27FBBD3B3CB9AAAF',
            Gy       => '7DEBE8E4E90A5DAE6E4054CA530BA04654B36818CE226B39FCCB7B02F1AE',
            order    => '7FFFFFFFFFFFFFFFFFFFFFFF7FFFFF9E5E9A9F5D9071FBD1522688909D0B',
            cofactor => 1,
        },
        prime239v2 => {
            prime    => '7FFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFF8000000000007FFFFFFFFFFF',
            A        => '7FFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFF8000000000007FFFFFFFFFFC',
            B        => '617FAB6832576CBBFED50D99F0249C3FEE58B94BA0038C7AE84C8C832F2C',
            Gx       => '38AF09D98727705120C921BB5E9E26296A3CDCF2F35757A0EAFD87B830E7',
            Gy       => '5B0125E4DBEA0EC7206DA0FC01D9B081329FB555DE6EF460237DFF8BE4BA',
            order    => '7FFFFFFFFFFFFFFFFFFFFFFF800000CFA7E8594377D414C03821BC582063',
            cofactor => 1,
        },
        prime239v3 => {
            prime    => '7FFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFF8000000000007FFFFFFFFFFF',
            A        => '7FFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFF8000000000007FFFFFFFFFFC',
            B        => '255705FA2A306654B1F4CB03D6A750A30C250102D4988717D9BA15AB6D3E',
            Gx       => '6768AE8E18BB92CFCF005C949AA2C6D94853D0E660BBF854B1C9505FE95A',
            Gy       => '1607E6898F390C06BC1D552BAD226F3B6FCFE48B6E818499AF18E3ED6CF3',
            order    => '7FFFFFFFFFFFFFFFFFFFFFFF7FFFFF975DEB41B3A6057C3C432146526551',
            cofactor => 1,
        },
        prime256v1 => {
            prime    => 'FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF',
            A        => 'FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC',
            B        => '5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B',
            Gx       => '6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296',
            Gy       => '4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5',
            order    => 'FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551',
            cofactor => 1,
        },
);

sub new {
  my ($class, $f, $p) = @_;
  my $self = _new();
  $self->import_key($f, $p) if $f;
  return  $self;
}

sub export_key_pem {
  my ($self, $type, $password, $cipher) = @_;
  my $key = $self->export_key_der($type||'');
  return undef unless $key;
  return Crypt::PK::_asn1_to_pem($key, "EC PRIVATE KEY", $password, $cipher) if $type eq 'private';  
  return Crypt::PK::_asn1_to_pem($key, "PUBLIC KEY") if $type eq 'public' || $type eq 'public_compressed';
}

sub import_key {
  my ($self, $key, $password) = @_;
  croak "FATAL: undefined key" unless $key;
  my $data;
  if (ref($key) eq 'SCALAR') {
    $data = $$key;
  }
  elsif (-f $key) {
    $data = Crypt::PK::_slurp_file($key);
  }
  else {
    croak "FATAL: non-existing file '$key'";
  }
  if ($data && $data =~ /-----BEGIN (EC PRIVATE|EC PUBLIC|PRIVATE|PUBLIC) KEY-----(.*?)-----END/sg) {
    $data = Crypt::PK::_pem_to_asn1($data, $password);
  }
  croak "FATAL: invalid key format" unless $data;
  return $self->_import($data);
}

sub encrypt {
  my ($self, $data, $hash_name) = @_;
  $hash_name = Crypt::Digest::_trans_digest_name($hash_name||'SHA1');
  return $self->_encrypt($data, $hash_name);
}

sub decrypt {
  my ($self, $data) = @_;
  return $self->_decrypt($data);
}

sub sign_message {
  my ($self, $data, $hash_name) = @_;
  $hash_name ||= 'SHA1';
  my $data_hash = digest_data($hash_name, $data);
  return $self->_sign($data_hash);
}

sub verify_message {
  my ($self, $sig, $data, $hash_name) = @_;
  $hash_name ||= 'SHA1';
  my $data_hash = digest_data($hash_name, $data);
  return $self->_verify($sig, $data_hash);
}

sub sign_hash {
  my ($self, $data_hash) = @_;
  return $self->_sign($data_hash);
}

sub verify_hash {
  my ($self, $sig, $data_hash) = @_;
  return $self->_verify($sig, $data_hash);
}

### FUNCTIONS

sub ecc_encrypt {
  my $key = shift;
  $key = __PACKAGE__->new($key) unless ref $key;
  carp "FATAL: invalid 'key' param" unless ref($key) eq __PACKAGE__;
  return $key->encrypt(@_);
}

sub ecc_decrypt {
  my $key = shift;
  $key = __PACKAGE__->new($key) unless ref $key;
  carp "FATAL: invalid 'key' param" unless ref($key) eq __PACKAGE__;
  return $key->decrypt(@_);
}

sub ecc_sign_message {
  my $key = shift;
  $key = __PACKAGE__->new($key) unless ref $key;
  carp "FATAL: invalid 'key' param" unless ref($key) eq __PACKAGE__;
  return $key->sign_message(@_);
}

sub ecc_verify_message {
  my $key = shift;
  $key = __PACKAGE__->new($key) unless ref $key;
  carp "FATAL: invalid 'key' param" unless ref($key) eq __PACKAGE__;
  return $key->verify_message(@_);
}

sub ecc_sign_hash {
  my $key = shift;
  $key = __PACKAGE__->new($key) unless ref $key;
  carp "FATAL: invalid 'key' param" unless ref($key) eq __PACKAGE__;
  return $key->sign_hash(@_);
}

sub ecc_verify_hash {
  my $key = shift;
  $key = __PACKAGE__->new($key) unless ref $key;
  carp "FATAL: invalid 'key' param" unless ref($key) eq __PACKAGE__;
  return $key->verify_hash(@_);
}

sub ecc_shared_secret {
  my ($privkey, $pubkey) = @_;
  $privkey = __PACKAGE__->new($privkey) unless ref $privkey;
  $pubkey  = __PACKAGE__->new($pubkey)  unless ref $pubkey;
  carp "FATAL: invalid 'privkey' param" unless ref($privkey) eq __PACKAGE__ && $privkey->is_private;
  carp "FATAL: invalid 'pubkey' param"  unless ref($pubkey)  eq __PACKAGE__;
  return $privkey->shared_secret($pubkey);
}

sub CLONE_SKIP { 1 } # prevent cloning

1;

=pod

=head1 NAME

Crypt::PK::ECC - Public key cryptography based on EC

=head1 SYNOPSIS

 ### OO interface

 #Encryption: Alice
 my $pub = Crypt::PK::ECC->new('Bob_pub_ecc1.der');
 my $ct = $pub->encrypt("secret message");
 #
 #Encryption: Bob (received ciphertext $ct)
 my $priv = Crypt::PK::ECC->new('Bob_priv_ecc1.der');
 my $pt = $priv->decrypt($ct);

 #Signature: Alice
 my $priv = Crypt::PK::ECC->new('Alice_priv_ecc1.der');
 my $sig = $priv->sign_message($message);
 #
 #Signature: Bob (received $message + $sig)
 my $pub = Crypt::PK::ECC->new('Alice_pub_ecc1.der');
 $pub->verify_message($sig, $message) or die "ERROR";

 #Shared secret
 my $priv = Crypt::PK::ECC->new('Alice_priv_ecc1.der');
 my $pub = Crypt::PK::ECC->new('Bob_pub_ecc1.der');
 my $shared_secret = $priv->shared_secret($pub);

 #Key generation
 my $pk = Crypt::PK::ECC->new();
 $pk->generate_key('secp160r1');
 my $private_der = $pk->export_key_der('private');
 my $public_der = $pk->export_key_der('public');
 my $private_pem = $pk->export_key_pem('private');
 my $public_pem = $pk->export_key_pem('public');
 my $public_raw = $pk->export_key_raw('public');

 ### Functional interface

 #Encryption: Alice
 my $ct = ecc_encrypt('Bob_pub_ecc1.der', "secret message");
 #Encryption: Bob (received ciphertext $ct)
 my $pt = ecc_decrypt('Bob_priv_ecc1.der', $ct);

 #Signature: Alice
 my $sig = ecc_sign_message('Alice_priv_ecc1.der', $message);
 #Signature: Bob (received $message + $sig)
 ecc_verify_message('Alice_pub_ecc1.der', $sig, $message) or die "ERROR";

 #Shared secret
 my $shared_secret = ecc_shared_secret('Alice_priv_ecc1.der', 'Bob_pub_ecc1.der');

=head1 DESCRIPTION

The module provides a set of core ECC functions as well as implementation of ECDSA and ECDH.

Supports elliptic curves C<y^2 = x^3 + a*x + b> over prime fields C<Fp = Z/pZ> (binary fields not supported).

=head1 METHODS

=head2 new

  my $pk = Crypt::PK::ECC->new();
  #or
  my $pk = Crypt::PK::ECC->new($priv_or_pub_key_filename);
  #or
  my $pk = Crypt::PK::ECC->new(\$buffer_containing_priv_or_pub_key);

Support for password protected PEM keys

  my $pk = Crypt::PK::ECC->new($priv_pem_key_filename, $password);
  #or
  my $pk = Crypt::PK::ECC->new(\$buffer_containing_priv_pem_key, $password);

=head2 generate_key

Uses Yarrow-based cryptographically strong random number generator seeded with
random data taken from C</dev/random> (UNIX) or C<CryptGenRandom> (Win32).

 $pk->generate_key($curve_name);
 #or
 $pk->generate_key($hashref_with_curve_params);

The following pre-defined C<$curve_name> values are supported:

 # curves from http://www.ecc-brainpool.org/download/Domain-parameters.pdf
 'brainpoolP160r1'
 'brainpoolP192r1'
 'brainpoolP224r1'
 'brainpoolP256r1'
 'brainpoolP320r1'
 'brainpoolP384r1'
 'brainpoolP512r1'
 # curves from http://www.secg.org/collateral/sec2_final.pdf
 'secp112r1'
 'secp112r2'
 'secp128r1'
 'secp128r2'
 'secp160k1'
 'secp160r1'
 'secp160r2'
 'secp192k1'
 'secp192r1'
 'secp224k1'
 'secp224r1'
 'secp256k1' ... used by Bitcoin
 'secp256r1'
 'secp384r1'
 'secp521r1'
 #curves from http://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.186-4.pdf
 'nistp192'
 'nistp224'
 'nistp256'
 'nistp384'
 'nistp521'
 # curves from ANS X9.62
 'prime192v1'
 'prime192v2'
 'prime192v3'
 'prime239v1'
 'prime239v2'
 'prime239v3'
 'prime256v1' 

Using custom curve parameters:

 $pk->generate_key({ prime    => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFF',
                     A        => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFC',
                     B        => '22123DC2395A05CAA7423DAECCC94760A7D462256BD56916',
                     Gx       => '7D29778100C65A1DA1783716588DCE2B8B4AEE8E228F1896',
                     Gy       => '38A90F22637337334B49DCB66A6DC8F9978ACA7648A943B0',
                     order    => 'FFFFFFFFFFFFFFFFFFFFFFFF7A62D031C83F4294F640EC13',
                     cofactor => 1 });

See L<http://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.186-4.pdf>, L<http://www.secg.org/collateral/sec2_final.pdf>, L<http://www.ecc-brainpool.org/download/Domain-parameters.pdf>

=head2 import_key

Loads private or public key in DER or PEM format.

  $pk->import_key($filename);
  #or
  $pk->import_key(\$buffer_containing_key);

Support for password protected PEM keys

  $pk->import_key($pem_filename, $password);
  #or
  $pk->import_key(\$buffer_containing_pem_key, $password);

=head2 import_key_raw

Import raw public/private key - can load data exported by L</export_key_raw>.

 $pk->import_key_raw($key, $curve);
 # $key .... data exported by export_key_raw()
 # $curve .. curve name or hashref with curve parameters - same as by generate_key()

=head2 export_key_der

 my $private_der = $pk->export_key_der('private');
 #or
 my $public_der = $pk->export_key_der('public');

=head2 export_key_pem

 my $private_pem = $pk->export_key_pem('private');
 #or
 my $public_pem = $pk->export_key_pem('public');

Support for password protected PEM keys

 my $private_pem = $pk->export_key_pem('private', $password);
 #or
 my $private_pem = $pk->export_key_pem('private', $password, $cipher);

 # supported ciphers: 'DES-CBC'
 #                    'DES-EDE3-CBC'
 #                    'SEED-CBC'
 #                    'CAMELLIA-128-CBC'
 #                    'CAMELLIA-192-CBC'
 #                    'CAMELLIA-256-CBC'
 #                    'AES-128-CBC'
 #                    'AES-192-CBC'
 #                    'AES-256-CBC' (DEFAULT)

=head2 export_key_raw

Export raw public/private key. Public key is exported in ANS X9.63 format (compressed or uncompressed),
private key is exported as raw bytes (padded with leading zeros to have the same size as the ECC curve).

 my $pubkey_octets  = $pk->export_key_raw('public');
 #or
 my $pubckey_octets = $pk->export_key_raw('public_compressed');
 #or
 my $privkey_octets = $pk->export_key_raw('private');

=head2 encrypt

 my $pk = Crypt::PK::ECC->new($pub_key_filename);
 my $ct = $pk->encrypt($message);
 #or
 my $ct = $pk->encrypt($message, $hash_name);

 #NOTE: $hash_name can be 'SHA1' (DEFAULT), 'SHA256' or any other hash supported by Crypt::Digest

=head2 decrypt

 my $pk = Crypt::PK::ECC->new($priv_key_filename);
 my $pt = $pk->decrypt($ciphertext);

=head2 sign_message

 my $pk = Crypt::PK::ECC->new($priv_key_filename);
 my $signature = $priv->sign_message($message);
 #or
 my $signature = $priv->sign_message($message, $hash_name);

 #NOTE: $hash_name can be 'SHA1' (DEFAULT), 'SHA256' or any other hash supported by Crypt::Digest

=head2 verify_message

 my $pk = Crypt::PK::ECC->new($pub_key_filename);
 my $valid = $pub->verify_message($signature, $message)
 #or
 my $valid = $pub->verify_message($signature, $message, $hash_name);

 #NOTE: $hash_name can be 'SHA1' (DEFAULT), 'SHA256' or any other hash supported by Crypt::Digest

=head2 sign_hash

 my $pk = Crypt::PK::ECC->new($priv_key_filename);
 my $signature = $priv->sign_hash($message_hash);

=head2 verify_hash

 my $pk = Crypt::PK::ECC->new($pub_key_filename);
 my $valid = $pub->verify_hash($signature, $message_hash);

=head2 shared_secret

  # Alice having her priv key $pk and Bob's public key $pkb
  my $pk  = Crypt::PK::ECC->new($priv_key_filename);
  my $pkb = Crypt::PK::ECC->new($pub_key_filename);
  my $shared_secret = $pk->shared_secret($pkb);

  # Bob having his priv key $pk and Alice's public key $pka
  my $pk = Crypt::PK::ECC->new($priv_key_filename);
  my $pka = Crypt::PK::ECC->new($pub_key_filename);
  my $shared_secret = $pk->shared_secret($pka);  # same value as computed by Alice

=head2 is_private

 my $rv = $pk->is_private;
 # 1 .. private key loaded
 # 0 .. public key loaded
 # undef .. no key loaded

=head2 size

 my $size = $pk->size;
 # returns key size in bytes or undef if no key loaded

=head2 key2hash

 my $hash = $pk->key2hash;

 # returns hash like this (or undef if no key loaded):
 {
   size           => 20, # integer: key (curve) size in bytes
   type           => 1,  # integer: 1 .. private, 0 .. public
   #curve parameters
   curve_A        => "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFC",
   curve_B        => "1C97BEFC54BD7A8B65ACF89F81D4D4ADC565FA45",
   curve_bits     => 160,
   curve_bytes    => 20,
   curve_cofactor => 1,
   curve_Gx       => "4A96B5688EF573284664698968C38BB913CBFC82",
   curve_Gy       => "23A628553168947D59DCC912042351377AC5FB32",
   curve_name     => "secp160r1",
   curve_order    => "0100000000000000000001F4C8F927AED3CA752257",
   curve_prime    => "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFF",
   #private key
   k              => "B0EE84A749FE95DF997E33B8F333E12101E824C3",
   #public key point coordinates
   pub_x          => "5AE1ACE3ED0AEA9707CE5C0BCE014F6A2F15023A",
   pub_y          => "895D57E992D0A15F88D6680B27B701F615FCDC0F",
 }

=head1 FUNCTIONS

=head2 ecc_encrypt

Elliptic Curve Diffie-Hellman (ECDH) encryption as implemented by libtomcrypt. See method L</encrypt> below.

 my $ct = ecc_encrypt($pub_key_filename, $message);
 #or
 my $ct = ecc_encrypt(\$buffer_containing_pub_key, $message);
 #or
 my $ct = ecc_encrypt($pub_key_filename, $message, $hash_name);

 #NOTE: $hash_name can be 'SHA1' (DEFAULT), 'SHA256' or any other hash supported by Crypt::Digest

ECCDH Encryption is performed by producing a random key, hashing it, and XOR'ing the digest against the plaintext.

=head2 ecc_decrypt

Elliptic Curve Diffie-Hellman (ECDH) decryption as implemented by libtomcrypt. See method L</decrypt> below.

 my $pt = ecc_decrypt($priv_key_filename, $ciphertext);
 #or
 my $pt = ecc_decrypt(\$buffer_containing_priv_key, $ciphertext);

=head2 ecc_sign_message

Elliptic Curve Digital Signature Algorithm (ECDSA) - signature generation. See method L</sign_message> below.

 my $sig = ecc_sign_message($priv_key_filename, $message);
 #or
 my $sig = ecc_sign_message(\$buffer_containing_priv_key, $message);
 #or
 my $sig = ecc_sign_message($priv_key, $message, $hash_name);

=head2 ecc_verify_message

Elliptic Curve Digital Signature Algorithm (ECDSA) - signature verification. See method L</verify_message> below.

 ecc_verify_message($pub_key_filename, $signature, $message) or die "ERROR";
 #or
 ecc_verify_message(\$buffer_containing_pub_key, $signature, $message) or die "ERROR";
 #or
 ecc_verify_message($pub_key, $signature, $message, $hash_name) or die "ERROR";

=head2 ecc_sign_hash

Elliptic Curve Digital Signature Algorithm (ECDSA) - signature generation. See method L</sign_hash> below.

 my $sig = ecc_sign_hash($priv_key_filename, $message_hash);
 #or
 my $sig = ecc_sign_hash(\$buffer_containing_priv_key, $message_hash);

=head2 ecc_verify_hash

Elliptic Curve Digital Signature Algorithm (ECDSA) - signature verification. See method L</verify_hash> below.

 ecc_verify_hash($pub_key_filename, $signature, $message_hash) or die "ERROR";
 #or
 ecc_verify_hash(\$buffer_containing_pub_key, $signature, $message_hash) or die "ERROR";

=head2 ecc_shared_secret

Elliptic curve Diffie-Hellman (ECDH) - construct a Diffie-Hellman shared secret with a private and public ECC key. See method L</shared_secret> below.

 #on Alice side
 my $shared_secret = ecc_shared_secret('Alice_priv_ecc1.der', 'Bob_pub_ecc1.der');

 #on Bob side
 my $shared_secret = ecc_shared_secret('Bob_priv_ecc1.der', 'Alice_pub_ecc1.der');

=head1 OpenSSL interoperability

 ### let's have:
 # ECC private key in PEM format - eckey.priv.pem
 # ECC public key in PEM format  - eckey.pub.pem
 # data file to be signed - input.data

=head2 Sign by OpenSSL, verify by Crypt::PK::ECC

Create signature (from commandline):

 openssl dgst -sha1 -sign eckey.priv.pem -out input.sha1-ec.sig input.data

Verify signature (Perl code):

 use Crypt::PK::ECC;
 use Crypt::Digest 'digest_file';
 use File::Slurp 'read_file';

 my $pkec = Crypt::PK::ECC->new("eckey.pub.pem");
 my $signature = read_file("input.sha1-ec.sig", binmode=>':raw');
 my $valid = $pkec->verify_hash($signature, digest_file("SHA1", "input.data"), "SHA1", "v1.5");
 print $valid ? "SUCCESS" : "FAILURE";

=head2 Sign by Crypt::PK::ECC, verify by OpenSSL

Create signature (Perl code):

 use Crypt::PK::ECC;
 use Crypt::Digest 'digest_file';
 use File::Slurp 'write_file';

 my $pkec = Crypt::PK::ECC->new("eckey.priv.pem");
 my $signature = $pkec->sign_hash(digest_file("SHA1", "input.data"), "SHA1", "v1.5");
 write_file("input.sha1-ec.sig", {binmode=>':raw'}, $signature);

Verify signature (from commandline):

 openssl dgst -sha1 -verify eckey.pub.pem -signature input.sha1-ec.sig input.data

=head2 Keys generated by Crypt::PK::ECC

Generate keys (Perl code):

 use Crypt::PK::ECC;
 use File::Slurp 'write_file';

 my $pkec = Crypt::PK::ECC->new;
 $pkec->generate_key('secp160k1');
 write_file("eckey.pub.der",  {binmode=>':raw'}, $pkec->export_key_der('public'));
 write_file("eckey.priv.der", {binmode=>':raw'}, $pkec->export_key_der('private'));
 write_file("eckey.pub.pem",  $pkec->export_key_pem('public'));
 write_file("eckey.priv.pem", $pkec->export_key_pem('private'));
 write_file("eckey-passwd.priv.pem", $pkec->export_key_pem('private', 'secret'));

Use keys by OpenSSL:

 openssl ec -in eckey.priv.der -text -inform der
 openssl ec -in eckey.priv.pem -text
 openssl ec -in eckey-passwd.priv.pem -text -inform pem -passin pass:secret
 openssl ec -in eckey.pub.der -pubin -text -inform der
 openssl ec -in eckey.pub.pem -pubin -text 

=head2 Keys generated by OpenSSL

Generate keys:

 openssl ecparam -param_enc explicit -name prime192v3 -genkey -out eckey.priv.pem
 openssl ec -param_enc explicit -in eckey.priv.pem -out eckey.pub.pem -pubout
 openssl ec -param_enc explicit -in eckey.priv.pem -out eckey.priv.der -outform der
 openssl ec -param_enc explicit -in eckey.priv.pem -out eckey.pub.der -outform der -pubout
 openssl ec -param_enc explicit -in eckey.priv.pem -out eckey.privc.der -outform der -conv_form compressed
 openssl ec -param_enc explicit -in eckey.priv.pem -out eckey.pubc.der -outform der -pubout -conv_form compressed
 openssl ec -param_enc explicit -in eckey.priv.pem -passout pass:secret -des3 -out eckey-passwd.priv.pem

B<IMPORTANT:> it is necessary to use C<-param_enc explicit> option

Load keys (Perl code):

 use Crypt::PK::ECC;
 use File::Slurp 'write_file';

 my $pkec = Crypt::PK::ECC->new;
 $pkec->import_key("eckey.pub.der");
 $pkec->import_key("eckey.pubc.der");
 $pkec->import_key("eckey.priv.der");
 $pkec->import_key("eckey.privc.der");
 $pkec->import_key("eckey.pub.pem");
 $pkec->import_key("eckey.priv.pem");
 $pkec->import_key("eckey-passwd.priv.pem", "secret");

=head1 SEE ALSO

=over

=item * L<https://en.wikipedia.org/wiki/Elliptic_curve_cryptography|https://en.wikipedia.org/wiki/Elliptic_curve_cryptography>

=item * L<https://en.wikipedia.org/wiki/Elliptic_curve_Diffie%E2%80%93Hellman|https://en.wikipedia.org/wiki/Elliptic_curve_Diffie%E2%80%93Hellman>

=item * L<https://en.wikipedia.org/wiki/ECDSA|https://en.wikipedia.org/wiki/ECDSA>

=back
