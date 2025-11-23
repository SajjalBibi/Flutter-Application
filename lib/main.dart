// lib/main.dart
import 'package:babyshophub/AuthRolebase/UserDashboard.dart';
import 'package:babyshophub/AuthRolebase/admindrawer.dart';
import 'package:babyshophub/addToCart/admin/AdminOrdersPage.dart';
import 'package:babyshophub/addToCart/admin/UserOrdersPage.dart';
import 'package:babyshophub/addToCart/admin/add_edit_gallery_item_screen.dart';
import 'package:babyshophub/addToCart/admin/manage_gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:babyshophub/AuthRolebase/AdminDashboard.dart';
import 'package:babyshophub/AuthRolebase/ManageUsers.dart';
import 'package:babyshophub/AuthRolebase/SellerDashboard.dart';
import 'package:babyshophub/AuthRolebase/SignIn.dart';
import 'package:babyshophub/AuthRolebase/SignUp.dart';
import 'package:babyshophub/addToCart/AddCategory.dart';
import 'package:babyshophub/addToCart/Editcategory.dart';
import 'package:babyshophub/addToCart/ListCategories.dart';
import 'package:babyshophub/addToCart/addCard.dart';
import 'package:babyshophub/addToCart/cart_screen.dart';
import 'package:babyshophub/addToCart/checkout_page.dart';
import 'package:babyshophub/addToCart/product_list.dart';
import 'package:babyshophub/addToCart/viewList.dart';
import 'package:babyshophub/app_colors.dart'; // Custom colors import karein
// import 'package:babyshophub/bottomNavigationbar.dart';
  
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBwP6twXdJ9NdPVD3Cvjkg2emCGLGb_068",
      authDomain: "babyshophub-94757.firebaseapp.com",
      databaseURL: "https://babyshophub-94757-default-rtdb.firebaseio.com",
      projectId: "babyshophub-94757",
      storageBucket: "babyshophub-94757.appspot.com",
      messagingSenderId: "1041226950273",
      appId: "1:1041226950273:web:7542fea13282c36e5a4f80",
      measurementId: "G-268M622LZD",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BabyShop Hub',
      theme: ThemeData(
        primaryColor: AppColors.skyBlue,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.babyPink,
          primary: AppColors.skyBlue,
          secondary: AppColors.babyPink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.babyPink,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lavender,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      // home: const BottomNavigationScreen(),
      home: const HomePageAnimated(),

      
      routes: {
        '/cart': (context) => const CartScreen(),
        '/add': (context) => const AddCardScreen(),
        '/checkout': (context) => const CheckoutPage(),
        '/addcard': (context) => const ProductListPage(),
        '/admindashboard': (context) => AdminDashboard(),
        "/loginScreen": (context) => const SignIn(),
        "/ManageUsers": (context) => ManageUsers(),
        "/SellerDashboard": (context) => SellerDashboard(),
        "/register": (context) => const SignUp(),
        "/UserDashboard": (context) => const HomePageAnimated(),
        '/ListCrud': (context) => const Listfetchcrud(),
        '/edit': (context) => const EditCardscreen(
              id: "",
              name: "",
              description: "",
              ImageBase64: "",
            ),
        '/addCategory': (context) => const CategoriesAddScreen(),
        '/admindrawr': (context) => const AdminDrawer(),
        "/listCategory": (context) => const ListCategoryScreen(),
        "/listgallery": (context) => const AddEditGalleryItemScreen(),
        '/manageGallery': (context) => const ManageGalleryScreen(),
        '/userorderhistory': (context) => const UserOrdersPage(),
        '/admin_order': (context) => AdminOrdersPage(),

      },
    );
  }
}