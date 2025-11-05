class ComplaintForm {
  final String department;
  final List<FormFieldData> fields;

  ComplaintForm({required this.department, required this.fields});

  factory ComplaintForm.fromMap(Map<String, dynamic> map) {
    return ComplaintForm(
      department: map['department'],
      fields: (map['fields'] as List).map((e) => FormFieldData.fromMap(e)).toList(),
    );
  }
}

class FormFieldData {
  final String label;
  final String type; // text, number, dropdown, etc.

  FormFieldData({required this.label, required this.type});

  factory FormFieldData.fromMap(Map<String, dynamic> map) {
    return FormFieldData(
      label: map['label'],
      type: map['type'],
    );
  }
}
