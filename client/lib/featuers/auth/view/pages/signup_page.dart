import 'package:client/featuers/auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:client/core/theme/app_pallet.dart';
import 'package:client/featuers/auth/view/pages/login_page.dart';
import 'package:client/featuers/auth/view/widgets/auth_gradient_button.dart';
import 'package:client/featuers/auth/view/widgets/custome_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: formkey,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Sign Up", style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),),
          
              SizedBox(height: 30,),
          
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
              )
            ],
          ),
        ),
      )
    );
  }
}