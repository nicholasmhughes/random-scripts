#!/usr/bin/env python3

import collections
import json
from azure.eventhub import EventHubClient, Offset

connstring = ''
hub_name =  ''

try:
    CONSUMER_GROUP = "$default"
    OFFSET = Offset("-1")

    myclient = EventHubClient.from_connection_string(connstring, hub_name)

    myclient.add_receiver(CONSUMER_GROUP, "0", OFFSET, 1)

    myclient.run()

    for c in myclient.clients:
        for m in c.receive_message_batch():
            events = json.loads(bytes.decode(eval(m._body.__str__())))
            if 'records' in events:
                for r in events['records']:
                    print(r)
            elif isinstance(events, collections.Iterable):
                for r in events:
                    print(r)
            else:
                print(events)

    myclient.stop()

except KeyboardInterrupt:
    pass
