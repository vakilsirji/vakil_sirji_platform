import re

file_path = r'd:\Project\v1\vakil_sirji_platform\lib\features\customer\create_request_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update _buildTextField
old_textfield = '''  Widget _buildTextField(String key, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _getCtrl(key),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        maxLines: maxLines,
      ),
    );
  }'''

new_textfield = '''  Widget _buildTextField(String key, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _getCtrl(key),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.slate500, fontSize: 14),
          filled: true,
          fillColor: AppColors.slate50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.slate200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        maxLines: maxLines,
      ),
    );
  }'''
content = content.replace(old_textfield, new_textfield)

# 2. Update DropdownButtonFormField decorations
old_dropdown_decor = '''decoration: const InputDecoration(border: OutlineInputBorder()),'''
old_dropdown_decor_2 = '''decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),'''

new_dropdown_decor = '''decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.slate50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),'''

content = content.replace(old_dropdown_decor, new_dropdown_decor)
content = content.replace(old_dropdown_decor_2, new_dropdown_decor)

# 3. Update Options Container to AnimatedContainer and add BoxShadow
old_option1 = '''              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: _selectedOption == 1 ? Colors.amber.shade700 : AppColors.slate200, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedOption == 1 ? Colors.amber.shade50 : Colors.white,
                ),'''
new_option1 = '''              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: _selectedOption == 1 ? Colors.amber.shade700 : AppColors.slate200, width: _selectedOption == 1 ? 2 : 1),
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedOption == 1 ? Colors.amber.shade50 : Colors.white,
                  boxShadow: _selectedOption == 1 ? [BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 12, spreadRadius: 2)] : [],
                ),'''
content = content.replace(old_option1, new_option1)

old_option2 = '''              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: _selectedOption == 2 ? const Color(0xFF0F172A) : AppColors.slate200, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedOption == 2 ? AppColors.slate50 : Colors.white,
                ),'''
new_option2 = '''              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: _selectedOption == 2 ? const Color(0xFF0F172A) : AppColors.slate200, width: _selectedOption == 2 ? 2 : 1),
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedOption == 2 ? AppColors.slate50 : Colors.white,
                  boxShadow: _selectedOption == 2 ? [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.15), blurRadius: 12, spreadRadius: 2)] : [],
                ),'''
content = content.replace(old_option2, new_option2)

# 4. Update FilterChips
old_chip = '''                  return FilterChip(
                    label: Text(t.name),
                    selected: isSelected,'''
new_chip = '''                  return FilterChip(
                    label: Text(t.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0F172A).withOpacity(0.1),
                    checkmarkColor: const Color(0xFF0F172A),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? const Color(0xFF0F172A) : AppColors.slate200)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),'''
content = content.replace(old_chip, new_chip)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
