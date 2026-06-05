import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MediHubPage extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final Widget? bottomNavigationBar;

  const MediHubPage({
  super.key,
  required this.title,
  required this.child,
  this.floatingActionButton,
  this.showBackButton = true,
  this.bottomNavigationBar,
});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      floatingActionButton:
          floatingActionButton,

      bottomNavigationBar:
          bottomNavigationBar,

      body: Container(
        decoration:
            const BoxDecoration(
          gradient:
              LinearGradient(
            begin:
                Alignment.topCenter,
            end:
                Alignment.bottomCenter,
            colors:
                AppColors.gradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(
                height: 8,
              ),

              Container(
                margin:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                padding:
                    const EdgeInsets.all(
                  10,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.card
                          .withValues(
                    alpha: 0.75,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color:
                          AppColors.shadow,
                      blurRadius: 12,
                      offset:
                          Offset(
                        0,
                        4,
                      ),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    showBackButton
    ? Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          onTap: () {
            Navigator.pop(
              context,
            );
          },
          child: Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              color:
                  AppColors.primary,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child:
                const Icon(
              Icons.arrow_back_ios_new,
              color:
                  AppColors.card,
              size: 18,
            ),
          ),
        ),
      )
    : const SizedBox(
        width: 44,
      ),

                    Expanded(
                      child: Center(
                        child: Text(
                          title,
                          style:
                              const TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 44,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Expanded(
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}