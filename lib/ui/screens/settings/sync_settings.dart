import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/services/provider/user_notifier.dart';
import 'package:tipitaka_pali/services/repositories/fire_user_repository.dart';
import 'package:tipitaka_pali/l10n/app_localizations.dart';

class SyncSettingsView extends StatefulWidget {
  const SyncSettingsView({super.key});

  @override
  State<SyncSettingsView> createState() => _SyncSettingsViewState();
}

class _SyncSettingsViewState extends State<SyncSettingsView> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String selectedEmail = ''; // To store the selected email
  String? _emailVerificationError; // Add this line

  @override
  void initState() {
    super.initState();
    _emailController.text = Prefs.email;
    if (Prefs.oldPassword.isNotEmpty && Prefs.email == Prefs.oldUsername) {
      _passwordController.text = Prefs.oldPassword;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserNotifier>(builder: (context, notifier, child) {
      if (!Prefs.isSignedIn) {
        _emailController.clear();
        _passwordController.clear();
      }
      return Card(
        child: ExpansionTile(
          leading: const Icon(Icons.sync),
          title: Text(
            AppLocalizations.of(context)!.cloudSettings,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          children: [
            const SizedBox(height: 10),
            _inputFields(notifier),
          ],
        ),
      );
    });
  }

  Widget _inputFields(UserNotifier notifier) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _emailController.text),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return [Prefs.oldUsername].where((String option) {
                  return option.contains(textEditingValue.text.toLowerCase());
                });
              },
              optionsViewBuilder: (BuildContext context,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: SizedBox(
                      width: 350, // Set the width of the suggestions box
                      height:
                          100, // Set the height of the suggestions box, optional
                      child: ListView.builder(
                        padding: const EdgeInsets.all(10.0),
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return GestureDetector(
                            onTap: () {
                              onSelected(option);
                            },
                            child: ListTile(
                              title: Text(option),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              fieldViewBuilder: (
                BuildContext context,
                TextEditingController controller,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted,
              ) {
                _emailController = controller; // Syncing with _emailController
                return TextFormField(
                  controller: _emailController,
                  focusNode: focusNode,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.enterEmail;
                    }
                    if (!EmailValidator.validate(value)) {
                      return AppLocalizations.of(context)!.enterValidEmail;
                    }

                    return null;
                  },
                  onChanged: (value) {
                    Prefs.email = value;
                  },
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.email,
                    icon: const Icon(Icons.email),
                    errorText: _emailVerificationError, // Add this line
                  ),
                );
              },
              onSelected: (String selection) {
                selectedEmail = selection;
                _emailController.text = selectedEmail;
                _passwordController.text = Prefs.oldPassword;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _passwordController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.enterPassword;
                }
                if (value.length < 8) {
                  return AppLocalizations.of(context)!.passwordTooShort;
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.password,
                icon: const Icon(Icons.lock),
              ),
              obscureText: true,
              onChanged: (value) async {
                Prefs.password = value;
              },
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: Prefs.isSignedIn
                  ? () async {
                      // Sign out logic
                      FireUserRepository userRepository =
                          FireUserRepository(notifier: notifier);
                      await userRepository.signOut();
                    }
                  : () async {
                      // check to see if there is internet.
                      // if not give snack bar.
                      if (await InternetConnection().hasInternetAccess) {
                        // Sign in logic
                        FireUserRepository userRepository =
                            FireUserRepository(notifier: notifier);
                        try {
                          await userRepository.signIn(
                              _emailController.text, _passwordController.text);
                          _emailVerificationError = "";

                          _showSnackBar(
                              AppLocalizations.of(context)!.loginSuccess);
                          // Additional logic for successful login
                          if (Prefs.password != Prefs.oldPassword) {
                            _showSavePasswordDialog();
                          }
                        } catch (e) {
                          // Handle login failure
                          if (e.toString().contains("Email_not_verified")) {
                            setState(() {
                              _emailVerificationError =
                                  AppLocalizations.of(context)!
                                      .verificationNeeded;
                            });
                          } else {
                            _showSnackBar(
                                "${AppLocalizations.of(context)!.loginFailed} $e");
                          }
                        }
                      } // if internet connection
                      else {
                        _showSnackBar(
                            AppLocalizations.of(context)!.turnOnInternet);
                      }
                    },
              child: Text(Prefs.isSignedIn
                  ? AppLocalizations.of(context)!.signOut
                  : AppLocalizations.of(context)!.signIn),
            ),
            const SizedBox(height: 16.0),
            (Prefs.isSignedIn)
                ? const SizedBox.shrink()
                : ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        FireUserRepository userRepository =
                            FireUserRepository(notifier: notifier);
                        try {
                          await userRepository.register(
                              _emailController.text, _passwordController.text);
                          // Handle successful registration
                          _showSnackBar(AppLocalizations.of(context)!
                              .registrationSuccessful);
                        } catch (e) {
                          // Handle registration failure
                          _showSnackBar(
                              "${AppLocalizations.of(context)!.registrationFailed} $e");
                        }
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.register),
                  ),
            const SizedBox(height: 16.0),
            (Prefs.isSignedIn)
                ? const SizedBox.shrink()
                : ElevatedButton(
                    onPressed: () async {
                      await _showResetPasswordDialog(notifier);
                    },
                    child: Text(AppLocalizations.of(context)!.resetPassword),
                  ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 6),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _showSavePasswordDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog.
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.savePassword),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(AppLocalizations.of(context)!.savePasswordMessage),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.no),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.yes),
              onPressed: () {
                Prefs.oldUsername =
                    _emailController.text; // Save the current username
                Prefs.oldPassword =
                    _passwordController.text; // Save the current password
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showResetPasswordDialog(UserNotifier notifier) async {
    TextEditingController resetEmailController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog.
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.resetPassword),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(AppLocalizations.of(context)!.resetPasswordMessage),
                TextFormField(
                  controller: resetEmailController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.email,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.submit),
              onPressed: () async {
                if (resetEmailController.text.isNotEmpty) {
                  // Perform password reset
                  FireUserRepository userRepository =
                      FireUserRepository(notifier: notifier);
                  await userRepository.resetPassword(resetEmailController.text);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
