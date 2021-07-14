import json


class Deployment1:
    def __init__(self, name, self_service_url):
        self.name = name
        self.self_service_url = self_service_url
        self.audit_entries_link = 'Not Started'

    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__, sort_keys=True, indent=4)
