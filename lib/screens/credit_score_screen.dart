import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_spy/constants/app_colors.dart';
import 'package:green_spy/models/credit_model.dart';
import 'package:green_spy/services/credit_service.dart';
import 'package:green_spy/widgets/credit_widgets.dart';

class CreditScoreScreen extends StatefulWidget {
  const CreditScoreScreen({super.key});

  @override
  State<CreditScoreScreen> createState() => _CreditScoreScreenState();
}

class _CreditScoreScreenState extends State<CreditScoreScreen>
    with SingleTickerProviderStateMixin {
  final CreditScoreService _creditService = CreditScoreService();
  late AnimationController _animationController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scoreAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.primaryGreen,
        ),
        title: Text(
          'Credit Score',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _initializeDefaultScore(),
            icon: const Icon(Icons.add_rounded),
            color: AppColors.primaryGreen,
            tooltip: 'Add Score',
          ),
          IconButton(
            onPressed: () => _refreshScore(),
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.primaryGreen,
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<CreditScoreModel?>(
          stream: _creditService.getLatestCreditScore(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryGreen,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: GoogleFonts.inter(color: AppColors.errorRed),
                ),
              );
            }

            final creditScore = snapshot.data;

            if (creditScore == null) {
              return _buildEmptyState();
            }

            return _buildContent(creditScore);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUpdateScoreDialog(),
        backgroundColor: AppColors.primaryGreen,
        elevation: 8,
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: Text(
          'Update Score',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(CreditScoreModel creditScore) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Credit Score Gauge
          CreditScoreGauge(
            creditScore: creditScore,
            animation: _scoreAnimation,
          ),
          const SizedBox(height: 30),

          // Score Change Card
          FutureBuilder<int>(
            future: _creditService.getScoreChange(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Column(
                  children: [
                    ScoreChangeCard(scoreChange: snapshot.data!),
                    const SizedBox(height: 20),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Improvement Suggestions
          ImprovementSuggestionCard(
            suggestions: _creditService.getImprovementSuggestions(creditScore),
          ),
          const SizedBox(height: 25),

          // Credit Factors
          Text(
            'Credit Factors',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 15),

          ...creditScore.factors.entries.map((entry) {
            final icon = _getFactorIcon(entry.key);
            return Column(
              children: [
                CreditFactorCard(factor: entry.value, icon: icon),
                const SizedBox(height: 12),
              ],
            );
          }),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_score_rounded,
            size: 80,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 20),
          Text(
            'No credit score data',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Initialize your credit score tracking',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _initializeDefaultScore(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Initialize Score',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFactorIcon(String factorName) {
    switch (factorName) {
      case CreditFactorType.paymentHistory:
        return Icons.payment_rounded;
      case CreditFactorType.creditUtilization:
        return Icons.credit_card_rounded;
      case CreditFactorType.creditAge:
        return Icons.history_rounded;
      case CreditFactorType.creditMix:
        return Icons.account_balance_rounded;
      case CreditFactorType.newCredit:
        return Icons.new_releases_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Future<void> _initializeDefaultScore() async {
    try {
      final defaultScore = await _creditService.generateDefaultCreditScore();
      await _creditService.addCreditScore(defaultScore);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Credit score initialized successfully',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}', style: GoogleFonts.inter()),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _refreshScore() async {
    _animationController.reset();
    _animationController.forward();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Score refreshed', style: GoogleFonts.inter()),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _showUpdateScoreDialog() async {
    // You can create a dialog similar to ExpenseDialog for updating credit scores
    // For now, showing a simple message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Manual score update - Implement dialog as needed',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppColors.infoBlue,
      ),
    );
  }
}
