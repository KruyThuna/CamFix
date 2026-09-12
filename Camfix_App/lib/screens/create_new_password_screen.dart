import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_text_field.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CircleBackButton(
                    onPressed: () => Navigator.of(context).pop()),
              ),
              const SizedBox(height: 28),
              Text(AppStrings.t('createWord'), style: AppText.h1),
              Text(AppStrings.t('newPasswordTitle'), style: AppText.h1),
              const SizedBox(height: 16),
              Text(
                AppStrings.t('newPasswordHint'),
                style: AppText.body,
              ),
              const SizedBox(height: 20),
              AppTextField(
                hint: AppStrings.t('newPasswordField'),
                icon: Icons.lock_outline,
                controller: _password,
                obscureText: _obscure1,
                suffix: IconButton(
                  icon: Icon(
                    _obscure1
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.hintGrey,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                hint: AppStrings.t('confirmPasswordField'),
                icon: Icons.lock_outline,
                controller: _confirm,
                obscureText: _obscure2,
                suffix: IconButton(
                  icon: Icon(
                    _obscure2
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.hintGrey,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: AppStrings.t('save'),
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
