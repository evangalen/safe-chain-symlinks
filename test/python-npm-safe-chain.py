import subprocess
subprocess.check_call('npm safe-chain-verify', shell=True)
subprocess.check_call('npm install safe-chain-test', shell=True)
