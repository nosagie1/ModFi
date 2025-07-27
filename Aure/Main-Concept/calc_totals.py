import json
import subprocess

# Get the jobs data
result = subprocess.run(['curl', '-s', 'http://localhost:5000/api/jobs/1'], capture_output=True, text=True)
data = json.loads(result.stdout)

total_gross = sum(float(job['amount']) for job in data)
total_net = total_gross * 0.8  # After 20% commission

print(f'Total jobs: {len(data)}')
print(f'Total gross amount: ${total_gross:,.2f}')
print(f'Total net after commission (80%): ${total_net:,.2f}')
print()
print('Job breakdown by amount:')
for job in sorted(data, key=lambda x: float(x['amount']), reverse=True):
    print(f'- {job["client"]}: ${float(job["amount"]):,.2f} ({job["status"]})')