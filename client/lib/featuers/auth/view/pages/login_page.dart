import 'package:client/core/theme/app_pallet.dart';
import 'package:client/featuers/auth/repositories/auth_remote_repository.dart';
import 'package:client/featuers/auth/view/pages/signup_page.dart';
import 'package:client/featuers/auth/view/widgets/auth_gradient_button.dart';
import 'package:client/featuers/auth/view/widgets/custome_field.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final formkey = GlobalKey<FormState>();

  @override
  void dispose() {
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
              Text("Log In", style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),),
          
              SizedBox(height: 30,),
          
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
                buttonText: "Log In",
                onTap: () async {
                  final res = await AuthRemoteRepository().login(
                    email: emailController.text, 
                    password: passwordController.text
                  );

                  final val = switch (res) {
                    Left(value: final l) => l,
                    Right(value: final r) => r,
                  };
                },
              ),
        
              SizedBox(height: 12),
        
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SignupPage()));
                },
                child: RichText(
                  text: TextSpan(
                   text: "Don't have an account? ",
                   style: Theme.of(context).textTheme.titleMedium,
                   children: [
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