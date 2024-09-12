import maxminddb
import sys
import json
ipa = str(sys.argv[1])

ispdatajson = {}

with maxminddb.open_database('GeoLite2-City.mmdb') as reader:
    record = reader.get(ipa)

    if record:
       try: ispdatajson.update(record)
       except KeyError:
        pass

with maxminddb.open_database('GeoLite2-ASN.mmdb') as reader:
    record = reader.get(ipa)

    if record:
       try: ispdatajson.update(record)
       except KeyError:
        pass

print(json.dumps(ispdatajson))