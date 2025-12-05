import subprocess
import requests

username = "USERNAME"
token = "YOUR_TOKEN"

url = "https://api.github.com/user/repos?per_page=200"
headers = {"Authorization": f"token {token}"}

repos = requests.get(url, headers=headers).json()

for r in repos:
    clone_url = r["ssh_url"]
    print(f"Cloning {clone_url}")
    subprocess.run(["git", "clone", clone_url])
