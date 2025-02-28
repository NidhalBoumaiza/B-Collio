import 'package:bcalio/call-test/screens/sign_up.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../loading_holder.dart';
import '../services/firebase_service.dart';
import '../top_bar.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController password = TextEditingController();

  final TextEditingController email = TextEditingController();

  final formKey = GlobalKey<FormState>();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingHolder(
        isLoading: isLoading,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const TopBar(title: "Login", upperTitle: ''),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Log Into Your Account',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'example@domain.com',
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        controller: password,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: '********',
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          const Text("Don't have an account?"),
                          const SizedBox(
                            width: 10,
                          ),
                          // TextButton(
                          //   onPressed: () {
                          //     MyApp.navigatorKey.currentState
                          //         ?.push(MaterialPageRoute(
                          //       builder: (ctx) => const SignUp(),
                          //     ));
                          //   },
                          //   child: const Text('Sign up'),
                          // )
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      // SizedBox(
                      //   width: MediaQuery.of(context).size.width - 50,
                      //   child: ElevatedButton(
                      //     onPressed: () async {
                      //       final isValid = formKey.currentState?.validate();
                      //       if (isValid != true ||
                      //           email.text.isEmpty ||
                      //           password.text.isEmpty) {
                      //         return;
                      //       }
                      //       setState(() {
                      //         isLoading = true;
                      //       });
                      //
                      // final bool result = await FirebaseService.login(
                      //   email: email.text,
                      //   password: password.text,
                      // );
                      //
                      //       if (result && mounted) {
                      //         MainApp.navigatorKey.currentState
                      //             ?.pushAndRemoveUntil(
                      //           MaterialPageRoute(
                      //             builder: (ctx) => const Home(),
                      //           ),
                      //           (route) => false,
                      //         );
                      //       } else {
                      //         if (mounted) {
                      //           ScaffoldMessenger.of(context).showSnackBar(
                      //             const SnackBar(
                      //               content: Text("Something went wrong!"),
                      //             ),
                      //           );
                      //         }
                      //       }
                      //
                      //       setState(() {
                      //         isLoading = false;
                      //       });
                      //     },
                      //     child: const Text('Sign in'),
                      //   ),
                      // )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
