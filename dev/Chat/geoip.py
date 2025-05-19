import maxminddb
import sys
import json

x = 1
ispdatajson = {'updateFile': []}

for arg in sys.argv[1:]:

    ipa = str(sys.argv[x])
    ispdatajson[ipa] = {}

    try:
        with maxminddb.open_database('GeoLite2-City.mmdb') as reader:
            record = reader.get(ipa)
        try:
            ispdatajson[ipa].update(record)
        except (TypeError, KeyError):
            pass        
    except (FileNotFoundError, maxminddb.errors.InvalidDatabaseError):
        ispdatajson['updateFile'].append('City')

    try:
        with maxminddb.open_database('GeoLite2-ASN.mmdb') as reader:
            record = reader.get(ipa)
        try:
            ispdatajson[ipa].update(record)
        except (TypeError, KeyError):
            pass
    except (FileNotFoundError, maxminddb.errors.InvalidDatabaseError):
        ispdatajson['updateFile'].append('ASN')

    x += 1
    if len(ispdatajson['updateFile']) > 0:
        break

print(json.dumps(ispdatajson))