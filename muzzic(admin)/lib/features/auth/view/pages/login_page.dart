import 'package:client/core/theme/app_pallet.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/custome_field.dart';
import 'package:client/features/auth/view/pages/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/view/pages/home_page.dart';
import '../../viewmodel/auth_viewmodel.dart';
import '../widgets/auth_gradient_button.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final formkey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
    formkey.currentState!.validate();
  }
  @override
  Widget build(BuildContext context) {
    ref.watch(authViewmodelProvider.select((val) => val?.isLoading == true));

    ref.listen(authViewmodelProvider, 
    (_, next) {
      next?.when(
        data: (data) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const HomePage(),
            ),
                (_) => false,
          );
          AppBanner2.show(
              context,
              title: "Login Successful",
              message: "Welcome back, ${data.name}",
              contentType: ContentType.success
          );
        }, 
        error: (error, str) {
          print("==============: $error");
          AppBanner2.show(
              context,
              title: "Error in login auth",
              message: "$error",
              contentType: ContentType.failure
          );
          }, 
        loading: () {}
      );
    }
    );
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: formkey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text("Log In", style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),),
          
              const SizedBox(height: 30,),
          
              CustomeField(
                hintText: "Enter your Email",
                controller: emailController,
              ),
          
              const SizedBox(height: 12,),
          
              CustomeField(
                hintText: "Enter your Password",
                controller: passwordController,
                isObscureText: true,
              ),
          
              const SizedBox(height: 22),
        
              AuthGradientButton(
                buttonText: "Log In",
                onTap: () async {
                  if(formkey.currentState!.validate()) {
                    ref.read(authViewmodelProvider.notifier)
                    .logInUser(
                      email: emailController.text, 
                      password: passwordController.text
                    );
                  } else {
                    AppBanner2.show(
                        context,
                        title: "Missing Field",
                        message: "Please enter all fields",
                        contentType: ContentType.failure
                    );
                  }
                },
              ),

              const SizedBox(height: 12,),

              ElevatedButton(
                  onPressed: () async {
                await ref.read(authViewmodelProvider.notifier).signInWithGoogle();
              }, child: const Center(child: Text('Sign in with Google'),)),
        
              const SizedBox(height: 12),
        
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupPage()));
                },
                child: RichText(
                  text: TextSpan(
                   text: "Don't have an account? ",
                   style: Theme.of(context).textTheme.titleMedium,
                   children: const [
                    TextSpan(
                      text: "Sign up",
                      style: TextStyle(
                        color: Pallete.gradient2,
                        fontWeight: FontWeight.bold
                      )
                    )
                   ] 
                  )
                ),
              )
            ],
          ),
        ),
      )
    );
  }
}