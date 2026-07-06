import re

file_path = r'd:\Project\v1\vakil_sirji_platform\lib\features\customer\create_request_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add _selectedCoTenantIds
content = re.sub(
    r'(String\?\s+_selectedTenantId;)',
    r'\1\n  List<String> _selectedCoTenantIds = [];',
    content
)

# Add to _submit()
content = re.sub(
    r'(if \(_selectedOption == 2\) \{\s*manualDetails\[\'uploaded_files\'\] = _uploadedFiles;\s*\})',
    r'\1\n\n    if (_selectedCoTenantIds.isNotEmpty) {\n      manualDetails[\'co_tenant_ids\'] = _selectedCoTenantIds;\n    }',
    content
)

# Add FilterChips to Option 3
option3_tenant_dropdown = r'''(DropdownButtonFormField<String>\(
\s*value: _selectedTenantId,
\s*decoration: const InputDecoration\(border: OutlineInputBorder\(\)\),
\s*items: widget.tenants.map\(\(t\) => DropdownMenuItem\(value: t.id, child: Text\(t.name\)\)\).toList\(\),
\s*onChanged: \(val\) => setState\(\(\) => _selectedTenantId = val\),
\s*\),)'''

co_tenants_widget = r'''\1
            if (_selectedTenantId != null) ...[
              const SizedBox(height: 16),
              const Text('Add Co-Tenants (Optional)', style: TextStyle(color: AppColors.slate600, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: widget.tenants.where((t) => t.id != _selectedTenantId).map((t) {
                  final isSelected = _selectedCoTenantIds.contains(t.id);
                  return FilterChip(
                    label: Text(t.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCoTenantIds.add(t.id);
                        } else {
                          _selectedCoTenantIds.remove(t.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],'''

content = re.sub(option3_tenant_dropdown, co_tenants_widget, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

