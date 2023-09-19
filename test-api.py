#!/usr/bin/env python3
"""
Test the API to ensure results are as expected.
The initial data set should return 5 successful responses,
but the API needs to properly handle invalid ID's as well.
Counting from 1 - 10 should give a proper sampling.
"""
import subprocess
import requests

# Get the API Endpoint from terraform output
# Remove spaces with strip, remove quotes with replace, and convert to string.
TF_URL = subprocess.check_output("terraform output aws_api_endpoint",shell=True).strip()
URL = TF_URL.decode("utf-8").replace('"','')

print("API Endpoint: %s" % URL)
# Walk through the values and return the API responses for each.
i = 0
while i < 10:
  response = requests.get(URL, params={"carId":i})
  print("Requesting carID {}",i)
  print("\t{}".format(response.json()))
  print("")
  i += 1
