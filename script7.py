import re

file_path = r'd:\Project\v1\vakil_sirji_platform\lib\features\customer\create_request_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

replacement = '''  void initState() {
    super.initState();
    _selectedOption = widget.initialIsExisting ? 3 : 2;
    if (widget.initialPropertyId != null) {
      _selectedPropertyId = widget.initialPropertyId;
    } else if (widget.properties.isNotEmpty) {
      _selectedPropertyId = widget.properties.first.id;
    }
    if (widget.initialTenantId != null) {
      _selectedTenantId = widget.initialTenantId;
    } else if (widget.tenants.isNotEmpty) {
      _selectedTenantId = widget.tenants.first.id;
    }

    final selectedProperties = widget.properties.where((p) => p.id == _selectedPropertyId);
    if (selectedProperties.isNotEmpty) {
      final property = selectedProperties.first;
      _getCtrl('existing_rent_amount').text = property.rentAmount.toStringAsFixed(0);
      _getCtrl('existing_deposit_amount').text = property.depositAmount.toStringAsFixed(0);
      _getCtrl('existing_rent_pay_date').text = property.reminderDueDay.toString();
    }

    // Auto-fill Owner details'''

content = content.replace(
'''  void initState() {
    super.initState();
    _selectedOption = widget.initialIsExisting ? 3 : 2;
    if (widget.properties.isNotEmpty) _selectedPropertyId = widget.properties.first.id;
    if (widget.tenants.isNotEmpty) _selectedTenantId = widget.tenants.first.id;

    // Auto-fill Owner details''', replacement)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
