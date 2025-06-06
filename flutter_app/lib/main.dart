import 'package:flutter/material.dart';
import 'package:flutter_app/bloc/review_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
// import pages
import './screens/landing_page.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/signup_page.dart';
import './screens/books_page.dart';
import './screens/book_page.dart';
// import blocs
import './screens/auth/auth_cubit.dart';
import './bloc/books_bloc.dart';
import './bloc/reviews_bloc.dart';

void main() {
  runApp(MultiBlocProvider(providers: [
    BlocProvider<AuthCubit>(
      create: (BuildContext context) => AuthCubit(),
    ),
    BlocProvider<BooksBloc>(
      create: (BuildContext context) => BooksBloc()..add(FetchBooks()),
    ),
  ], child: const MyApp()));
}

final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const LandingPage();
      },
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginPage();
      },
    ),
    GoRoute(
      path: '/signup',
      builder: (BuildContext context, GoRouterState state) {
        return const SignupPage();
      },
    ),
    GoRoute(
      path: '/books',
      // protected route
      redirect: (context, state) {
        final authState = context.read<AuthCubit>().state;
        if (authState.status == AuthState.unauthenticated()) {
          return '/';
        }
      },
      builder: (BuildContext context, GoRouterState state) {
        final authState = context.read<AuthCubit>().state;
        final username = authState.username ?? "Guest";
        return BooksPage(username: username);
      },
    ),
    GoRoute(
      path: '/book/:id',
      // protected route
      redirect: (context, state) {
        final authState = context.read<AuthCubit>().state;
        if (authState.status == AuthState.unauthenticated()) {
          return '/';
        }
        return null;
      },
      builder: (context, state) {
        final bookId = int.tryParse(state.pathParameters['id'] ?? '');
        if (bookId == null) {
          return const SizedBox(
            child: Center(
              child: Text("bookId is null"),
            ),
          );
        }
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<BooksBloc>()),
            BlocProvider<ReviewsBloc>(
              create: (BuildContext context) =>
                  ReviewsBloc()..add(FetchReviews(bookId)),
            ),
            BlocProvider(
              create: (BuildContext context) => ReviewBloc(),
            )
          ],
          child: BookPage(id: bookId),
        );
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ink & Insight',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: GoogleFonts.lexendDecaTextTheme(),
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
