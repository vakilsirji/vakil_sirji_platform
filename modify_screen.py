import re
import sys

with open(r'd:\Project\v1\vakil_sirji_platform\lib\features\customer\create_request_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. State Vars
code = code.replace(
    "String? _selectedTenantId;",
    "String? _selectedTenantId;\n  int _coOwnerCount = 0;\n  int _coTenantCount = 0;"
)

# 2. _pickFile
old_pick_file = """  Future<void> _pickFile(String label) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _uploadedFiles[label] = result.files.first.name;
      });
    }
  }"""

new_pick_file = """  Future<void> _pickFile(String label, {bool allowMultiple = false}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      allowMultiple: allowMultiple,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        if (allowMultiple) {
          _uploadedFiles[label] = result.files.map((e) => e.name).join(', ');
        } else {
          _uploadedFiles[label] = result.files.first.name;
        }
      });
    }
  }"""
code = code.replace(old_pick_file, new_pick_file)

# 3. _buildUploadButton
old_build_upload = """  Widget _buildUploadButton(String label) {
    final uploaded = _uploadedFiles.containsKey(label);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ElevatedButton.icon(
            onPressed: () => _pickFile(label),"""
            
new_build_upload = """  Widget _buildUploadButton(String label, {bool allowMultiple = false}) {
    final uploaded = _uploadedFiles.containsKey(label);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ElevatedButton.icon(
            onPressed: () => _pickFile(label, allowMultiple: allowMultiple),"""
code = code.replace(old_build_upload, new_build_upload)

# 4. Upload Steps Content
old_upload_content = """            _buildUploadButton('Owner Aadhaar'),
            _buildUploadButton('Owner PAN'),
            const Divider(height: 32),
            _buildUploadButton('Tenant Aadhaar'),
            _buildUploadButton('Tenant PAN'),
            const Divider(height: 32),
            _buildUploadButton('Electricity Bill'),"""

new_upload_content = """            _buildUploadButton('Owner(s) Aadhaar', allowMultiple: true),
            _buildUploadButton('Owner(s) PAN', allowMultiple: true),
            const Divider(height: 32),
            _buildUploadButton('Tenant(s) Aadhaar', allowMultiple: true),
            _buildUploadButton('Tenant(s) PAN', allowMultiple: true),
            const Divider(height: 32),
            _buildUploadButton('Witness 1 Aadhaar'),
            _buildUploadButton('Witness 2 Aadhaar'),
            const Divider(height: 32),
            _buildUploadButton('Electricity Bill'),"""
code = code.replace(old_upload_content, new_upload_content)

# 5. Add Co-Owner
old_coowner = """            _buildTextField('owner_address', 'Current Address', maxLines: 2),
            const Divider(height: 32),
            Row("""

new_coowner = """            _buildTextField('owner_address', 'Current Address', maxLines: 2),
            for (int i = 1; i <= _coOwnerCount; i++) ...[
              const Divider(height: 16),
              Text('Co-Owner $i Details', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              _buildTextField('co_owner_${i}_name', 'Full Name'),
              Row(
                children: [
                  Expanded(child: _buildTextField('co_owner_${i}_age', 'Age')),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _buildTextField('co_owner_${i}_mobile', 'Mobile')),
                ],
              ),
              _buildTextField('co_owner_${i}_aadhaar', 'Aadhaar Number'),
              _buildTextField('co_owner_${i}_pan', 'PAN Number'),
            ],
            TextButton.icon(
              onPressed: () => setState(() => _coOwnerCount++), 
              icon: const Icon(Icons.add), 
              label: const Text('Add Co-Owner')
            ),
            const Divider(height: 32),
            Row("""
code = code.replace(old_coowner, new_coowner)

# 6. Add Co-Tenant
old_cotenant = """            _buildTextField('tenant_address', 'Current Address', maxLines: 2),
            _buildTextField('tenant_perm_address', 'Permanent Address', maxLines: 2),
          ],"""

new_cotenant = """            _buildTextField('tenant_address', 'Current Address', maxLines: 2),
            _buildTextField('tenant_perm_address', 'Permanent Address', maxLines: 2),
            for (int i = 1; i <= _coTenantCount; i++) ...[
              const Divider(height: 16),
              Text('Co-Tenant $i Details', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              _buildTextField('co_tenant_${i}_name', 'Full Name'),
              Row(
                children: [
                  Expanded(child: _buildTextField('co_tenant_${i}_age', 'Age')),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _buildTextField('co_tenant_${i}_mobile', 'Mobile')),
                ],
              ),
              _buildTextField('co_tenant_${i}_aadhaar', 'Aadhaar Number'),
              _buildTextField('co_tenant_${i}_pan', 'PAN Number'),
            ],
            TextButton.icon(
              onPressed: () => setState(() => _coTenantCount++), 
              icon: const Icon(Icons.add), 
              label: const Text('Add Co-Tenant')
            ),
          ],"""
code = code.replace(old_cotenant, new_cotenant)

# 7. Add Agreement Period Step for Option 1 and 2
old_common = """    // Common Steps (Documents and Review)
    steps.add(Step(
      title: const Text('Upload Documents', style: TextStyle(fontWeight: FontWeight.bold)),"""

new_common = """    if (_selectedOption == 1 || _selectedOption == 2) {
      steps.add(Step(
        title: const Text('Agreement Period', style: TextStyle(fontWeight: FontWeight.bold)),
        isActive: _currentStep >= steps.length,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _selectDate('existing_start_date'),
              child: IgnorePointer(
                child: _buildTextField('existing_start_date', 'Start Date (YYYY-MM-DD)'),
              ),
            ),
            Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) _calculateEndDate();
              },
              child: _buildTextField('existing_duration_months', 'Duration (Months)'),
            ),
            IgnorePointer(
              child: _buildTextField('existing_end_date', 'Calculated End Date'),
            ),
          ],
        ),
      ));
    }

    // Common Steps (Documents and Review)
    steps.add(Step(
      title: const Text('Upload Documents', style: TextStyle(fontWeight: FontWeight.bold)),"""
code = code.replace(old_common, new_common)

with open(r'd:\Project\v1\vakil_sirji_platform\lib\features\customer\create_request_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Modification complete")
