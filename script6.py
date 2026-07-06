import re

file_path = r'd:\Project\v1\vakil_sirji_platform\lib\features\customer\create_request_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add fields
content = content.replace(
    '  final bool initialIsExisting;',
    '  final bool initialIsExisting;\n  final String? initialPropertyId;\n  final String? initialTenantId;'
)

# Add to constructor
content = content.replace(
    '    this.initialIsExisting = false,\n  });',
    '    this.initialIsExisting = false,\n    this.initialPropertyId,\n    this.initialTenantId,\n  });'
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
