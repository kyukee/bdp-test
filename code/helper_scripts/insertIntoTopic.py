import requests
import base64
import json
import sys
from csv import reader

if len(sys.argv) != 3:
    print("incorrect command format. Should be:\n" + sys.argv[0] + " <csv file location> <name of target kafka topic>")
    exit(1)


topic = sys.argv[2]
url = "http://localhost:8082/topics/" + str(topic)

headers = {
'Content-Type': 'application/vnd.kafka.json.v2+json',
'Accept': 'application/vnd.kafka.v2+json',
}


file_location = sys.argv[1]

with open(file_location, 'rt') as sourceFile:

    res = reader(sourceFile, delimiter=',', quotechar='"')

    csv_headers = next(res, None)

    row_values = {}

    for line in res:

        for i in range(len(csv_headers)):
            header = csv_headers[i]
            row_values[header] = line[i]

        payload = {"records":
               [{
                   "value":row_values
               }]
        }

        # Send the message
        r = requests.post(url, headers=headers, data=json.dumps(payload))
        if r.status_code != 200:
           print("An error ocurred")
           print("Status Code: " + str(r.status_code))
           print(r.text)

print("Finished uploading to kafka topic")
