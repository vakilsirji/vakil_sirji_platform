import re

file_path = r'd:\Project\v1\vakil_sirji_platform\lib\features\customer\create_request_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r'^\s*_buildUploadButton\(\'Co-Owner \ Aadhaar\', allowMultiple: false\),\r?\n', '', content, flags=re.MULTILINE)
content = re.sub(r'^\s*_buildUploadButton\(\'Co-Tenant \ Aadhaar\', allowMultiple: false\),\r?\n', '', content, flags=re.MULTILINE)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
