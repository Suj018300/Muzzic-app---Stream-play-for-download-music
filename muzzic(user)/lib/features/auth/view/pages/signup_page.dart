import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:flutter/material.dart';
import 'package:client/core/theme/app_pallet.dart';
import 'package:client/core/widgets/custome_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

import '../../viewmodel/auth_viewmodel.dart';
import '../widgets/auth_gradient_button.dart';
import 'login_page.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});
  
  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final formkey = GlobalKey<FormState>();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
    // formkey.currentState!.validate();
  }
  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authViewmodelProvider.select((val) => val?.isLoading == true));

    ref.listen(authViewmodelProvider, 
    (_, next) {
      next?.when(
        data: (data) {
          AppBanner2.show(
              context,
              title: "Account Created Successfully",
              message: "Your account is created now please login",
              contentType: ContentType.success
          );
          Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
        }, 
        error: (error, str) {
          AppBanner2.show(
              context,
              title: "Failed to create account",
              message: "Oops, account has not been created please re-enter your credentials",
              contentType: ContentType.failure
          );
          }, 
        loading: () {}
      );
    }
    );
    return Scaffold(
      // appBar: AppBar(),
      body: isLoading ? const Loader() : Padding(
          padding: const EdgeInsets.all(18),
          child : Form(
        key: formkey,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text("Sign Up", style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),),
          
              const SizedBox(height: 30,),
          
              CustomeField(
                hintText: "Enter your Name",
                controller: nameController,
              ),
          
              SizedBox(height: 12,),
          
              CustomeField(
                hintText: "Enter your Email",
                controller: emailController,
              ),
          
              SizedBox(height: 12,),
          
              CustomeField(
                hintText: "Enter your Password",
                controller: passwordController,
                isObscureText: true,
              ),
          
              SizedBox(height: 22),
        
              AuthGradientButton(
                buttonText: "Sign Up",
                onTap: () async {
                  if (formkey.currentState!.validate()) {
                    await ref.read(
                    authViewmodelProvider.notifier).signUpUser(
                      name: nameController.text, 
                      email: emailController.text, 
                      password: passwordController.text
                    );
                  }
                },
              ),

              const SizedBox(height: 12,),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                        fixedSize: const Size(395, 55)
                    ),
                    onPressed: () async {
                      await ref.read(authViewmodelProvider.notifier).signInWithGoogle();
                    }, child: const Center(child: Text('Sign in with Google', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.deepPurple),),
                )),
              ),

              SizedBox(height: 12),
        
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
                },
                child: RichText(
                  text: TextSpan(
                   text: "Already have an account? ",
                   style: Theme.of(context).textTheme.titleMedium,
                   children: [
                    TextSpan(
                      text: "Log in",
                      style: TextStyle(
                        color: Pallete.gradient2,
                        fontWeight: FontWeight.bold
                      )
                    )
                   ] 
                  )
                ),
              ),
            ],
          ),
        ),
      )
    );
  }
}