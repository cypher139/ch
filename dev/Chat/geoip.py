import maxminddb
import sys
import json

x = 1
ispdatajson = {}

for arg in sys.argv[1:]:

    ipa = str(sys.argv[x])
    ispdatajson[ipa] = {}

    with maxminddb.open_database('GeoLite2-City.mmdb') as reader:
        record = reader.get(ipa)

        try:
            ispdatajson[ipa].update(record)
        except (TypeError, KeyError):
            pass

    with maxminddb.open_database('GeoLite2-ASN.mmdb') as reader:
        record = reader.get(ipa)

        try:
            ispdatajson[ipa].update(record)
        except (TypeError, KeyError):
            pass

    x += 1

print(json.dumps(ispdatajson))