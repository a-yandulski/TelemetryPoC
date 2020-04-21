import json
import requests
import sys
import csv
import datetime
import time

now = int(datetime.datetime.today().timestamp() * 1000)
lookback = 7 * 24 * 3600 * 1000 # 7 days in milliseconds
services_url = "http://localhost:16686/api/services"
dependencies_url = f"http://localhost:16686/api/dependencies?endTs={now}&lookback={lookback}"
io_requests = []
io_dependencies = []
io_requests_and_deps = []
separator = ", "

def main(args):
    global io_requests
    global io_dependencies
    global io_requests_and_deps

    services = requests.get(services_url).json()
    io_requests = list(filter(lambda x: x.startswith("IntelligentOffice.") or x.startswith("/"), services["data"]))
    dependencies = requests.get(dependencies_url).json()
    io_dependencies = list(filter(lambda x: x["parent"] != x["child"] and not (x["parent"].startswith("Microservice.") or x["parent"].startswith("Monolith.")), dependencies["data"]))

    for request in io_requests:
        request_with_deps = { }
        request_with_deps["page"] = request
        request_with_deps["uses_db"] = False
        request_with_deps["uses_api"] = False
        request_with_deps["api_dependencies"] = ""

        request_dependencies = list(map(lambda x: x["child"], filter(lambda y: y["parent"] == request, io_dependencies)))

        if len(request_dependencies) > 0:
            request_dependencies.sort()
            api_deps = list(filter(lambda x: x.startswith("Microservice.") or x.startswith("Monolith."), request_dependencies))
            db_deps = list(filter(lambda x: x.startswith("Sql"), request_dependencies)) #TODO:not yet implemented
            request_with_deps["uses_db"] = True if len(db_deps) > 0 else False
            request_with_deps["uses_api"] = True if len(api_deps) > 0 else False
            request_with_deps["api_dependencies"] = separator.join(api_deps)

        io_requests_and_deps.append(request_with_deps)

    io_requests_and_deps.sort(key = lambda x: x["page"])

    for io_request in io_requests_and_deps:
        print(f"{io_request['page']}\t{io_request['uses_db']}\t{io_request['uses_api']}\t{io_request['api_dependencies']}")

    if len(io_requests_and_deps) == 0:
        return

    keys = io_requests_and_deps[0].keys()

    with open('io_dependencies.csv', 'w+', newline='') as output_file:
        writer = csv.DictWriter(output_file, keys)
        writer.writeheader()
        writer.writerows(io_requests_and_deps)

    return


if __name__ == "__main__":
    main(sys.argv[1:])