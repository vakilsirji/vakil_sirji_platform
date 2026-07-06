import os

file_path = r'd:\Project\v1\vakil_sirji_platform\lib\features\customer\create_request_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(r"manualDetails[\'co_tenant_ids\']", "manualDetails['co_tenant_ids']")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
