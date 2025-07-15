import 'lib/services/bmi_recommendations_service.dart';

void main() {
  print('Testing Obesity Classes Implementation:');
  print('=====================================');
  
  // Test BMI values for each obesity class
  List<double> testBMIs = [29.9, 30.0, 32.5, 35.0, 37.5, 40.0, 45.0];
  
  for (double bmi in testBMIs) {
    String category = BMIRecommendationsService.getBMICategory(bmi);
    print('BMI: ${bmi.toStringAsFixed(1)} -> Category: $category');
  }
  
  print('\nTesting Advice for Obesity Classes:');
  print('===================================');
  
  // Test advice for each obesity class
  List<String> obesityClasses = ['Obesity Class I', 'Obesity Class II', 'Obesity Class III'];
  
  for (String obesityClass in obesityClasses) {
    print('\n$obesityClass:');
    print('Meal Advice:');
    List<String> mealAdvice = BMIRecommendationsService.getMealAdvice(obesityClass);
    for (String advice in mealAdvice) {
      print('  - $advice');
    }
    
    print('Exercise Advice:');
    List<String> exerciseAdvice = BMIRecommendationsService.getExerciseAdvice(obesityClass);
    for (String advice in exerciseAdvice) {
      print('  - $advice');
    }
    
    print('Motivational Message:');
    String motivationalMessage = BMIRecommendationsService.getMotivationalMessage(obesityClass);
    print('  $motivationalMessage');
  }
} 