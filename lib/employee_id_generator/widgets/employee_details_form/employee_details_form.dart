import 'package:flutter/material.dart';
import 'package:magic_epaper_app/constants/color_constants.dart';
import 'package:magic_epaper_app/employee_id_generator/controller/employee_id_controller.dart';
import 'package:magic_epaper_app/employee_id_generator/widgets/employee_details_form/employee_form_field.dart';
import 'package:magic_epaper_app/employee_id_generator/widgets/employee_details_form/profile_image_picker.dart';

class EmployeeDetailsForm extends StatelessWidget {
  final EmployeeIdController controller;
  final GlobalKey<FormState> formKey;
  final VoidCallback onChanged;

  const EmployeeDetailsForm({
    super.key,
    required this.controller,
    required this.formKey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_add,
                  color: colorAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Employee Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                ProfileImagePicker(
                  controller: controller,
                  onTap: () => controller.pickProfileImage(context),
                  onRemove: () => controller.removeProfileImage(context),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tap to add or change photo',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Basic Information', Icons.person),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: EmployeeFormField(
                  controller: controller.nameController,
                  label: 'Full Name',
                  icon: Icons.person,
                  validationType: ValidationType.required,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: EmployeeFormField(
                  controller: controller.idController,
                  label: 'Employee ID',
                  icon: Icons.badge,
                  validationType: ValidationType.required,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSectionHeader('Job Information', Icons.work),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: EmployeeFormField(
                  controller: controller.designationController,
                  label: 'Designation',
                  icon: Icons.work,
                  validationType: ValidationType.required,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: EmployeeFormField(
                  controller: controller.departmentController,
                  label: 'Department',
                  icon: Icons.business,
                  validationType: ValidationType.required,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSectionHeader('Contact Information', Icons.contact_mail),
          const SizedBox(height: 16),
          EmployeeFormField(
            controller: controller.emailController,
            label: 'Email Address',
            icon: Icons.email,
            validationType: ValidationType.email,
            onChanged: onChanged,
          ),
          EmployeeFormField(
            controller: controller.phoneController,
            label: 'Phone Number',
            icon: Icons.phone,
            validationType: ValidationType.phone,
            onChanged: onChanged,
          ),
          const SizedBox(height: 8),
          _buildSectionHeader('Company Information', Icons.business_center),
          const SizedBox(height: 16),
          EmployeeFormField(
            controller: controller.companyController,
            label: 'Company Name',
            icon: Icons.business_center,
            validationType: ValidationType.required,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: colorAccent,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }
}
