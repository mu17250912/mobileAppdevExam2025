class BMIRecommendationsService {
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal weight';
    if (bmi < 30.0) return 'Overweight';
    if (bmi < 35.0) return 'Obesity Class I';
    if (bmi < 40.0) return 'Obesity Class II';
    return 'Obesity Class III';
  }

  static List<String> getMealAdvice(String category) {
    switch (category) {
      case 'Underweight':
        return [
          '🍎 Increase calorie intake with healthy foods',
          '🥛 Drink whole milk and smoothies',
          '🥜 Add nuts and seeds to your meals',
          '🥑 Include healthy fats like avocado',
          '🍗 Eat lean proteins (chicken, fish, eggs)',
          '🍚 Choose whole grains for energy',
          '🥛 Consider protein shakes between meals',
          '⏰ Eat 5-6 small meals throughout the day'
        ];
      case 'Normal weight':
        return [
          '🥗 Maintain a balanced diet',
          '🍎 Eat plenty of fruits and vegetables',
          '🥩 Include lean proteins in every meal',
          '🌾 Choose whole grains over refined grains',
          '🥛 Stay hydrated with water and milk',
          '🥜 Include healthy fats in moderation',
          '🍽️ Practice portion control',
          '⏰ Eat regular meals at consistent times'
        ];
      case 'Overweight':
        return [
          '🥗 Focus on vegetables and lean proteins',
          '🍎 Limit processed foods and added sugars',
          '💧 Drink plenty of water throughout the day',
          '🍽️ Use smaller plates to control portions',
          '🥛 Choose low-fat dairy products',
          '🌾 Eat whole grains for fiber',
          '⏰ Avoid eating late at night',
          '📝 Keep a food diary to track intake'
        ];
      case 'Obesity Class I':
        return [
          '🥗 Start with small, sustainable changes',
          '💧 Drink water before meals to feel full',
          '🍎 Focus on whole, unprocessed foods',
          '🍽️ Use portion control tools',
          '🥛 Choose low-calorie beverages',
          '🌾 Increase fiber intake gradually',
          '⏰ Eat slowly and mindfully',
          '📞 Consider consulting a nutritionist'
        ];
      case 'Obesity Class II':
        return [
          '🥗 Work with a registered dietitian for meal planning',
          '💧 Drink water before meals to feel full',
          '🍎 Focus on whole, unprocessed foods',
          '🍽️ Use portion control tools and food scales',
          '🥛 Choose low-calorie beverages only',
          '🌾 Increase fiber intake gradually',
          '⏰ Eat slowly and mindfully',
          '📞 Consult a healthcare provider for medical supervision'
        ];
      case 'Obesity Class III':
        return [
          '🥗 Medical supervision required for diet planning',
          '💧 Stay hydrated with water throughout the day',
          '🍎 Focus on whole, unprocessed foods',
          '🍽️ Strict portion control with medical guidance',
          '🥛 Avoid sugary beverages completely',
          '🌾 High-fiber foods for satiety',
          '⏰ Eat slowly and mindfully',
          '📞 Immediate consultation with healthcare provider required'
        ];
      default:
        return ['Please consult a healthcare provider for personalized advice.'];
    }
  }

  static List<String> getExerciseAdvice(String category) {
    switch (category) {
      case 'Underweight':
        return [
          '🏋️ Focus on strength training to build muscle',
          '🚴 Start with light cardio (walking, cycling)',
          '🧘 Include yoga for flexibility and stress relief',
          '🏊 Swimming is great for full-body workout',
          '💪 Use resistance bands for muscle building',
          '🚶 Take regular walks to build endurance',
          '🏃 Gradually increase exercise intensity',
          '📈 Track your progress and celebrate gains'
        ];
      case 'Normal weight':
        return [
          '🏃‍♀️ Mix cardio and strength training',
          '🚴 Cycling or jogging 3-4 times per week',
          '🏋️ Strength training 2-3 times per week',
          '🧘 Yoga or Pilates for flexibility',
          '🏊 Swimming for low-impact cardio',
          '🚶 Walking 10,000 steps daily',
          '⚽ Play sports you enjoy',
          '📅 Aim for 150 minutes of exercise weekly'
        ];
      case 'Overweight':
        return [
          '🚶 Start with walking 30 minutes daily',
          '🏊 Swimming is excellent for joints',
          '🚴 Low-impact cycling to build endurance',
          '🧘 Gentle yoga for flexibility',
          '💪 Light strength training with body weight',
          '🏃 Gradually increase cardio intensity',
          '📱 Use fitness apps to track progress',
          '👥 Consider joining group exercise classes'
        ];
      case 'Obesity Class I':
        return [
          '🚶 Start with short walks (10-15 minutes)',
          '🏊 Swimming is ideal for low-impact exercise',
          '🧘 Chair yoga for gentle movement',
          '💪 Light stretching and flexibility exercises',
          '🚴 Stationary cycling at comfortable pace',
          '📈 Set small, achievable fitness goals',
          '👨‍⚕️ Consult doctor before starting exercise',
          '📱 Use step counter to track daily movement'
        ];
      case 'Obesity Class II':
        return [
          '🚶 Start with very short walks (5-10 minutes)',
          '🏊 Swimming is excellent for low-impact exercise',
          '🧘 Chair yoga and gentle stretching',
          '💪 Light range-of-motion exercises',
          '🚴 Stationary cycling at very slow pace',
          '📈 Set very small, achievable fitness goals',
          '👨‍⚕️ Medical clearance required before exercise',
          '📱 Use step counter to track daily movement'
        ];
      case 'Obesity Class III':
        return [
          '🚶 Start with standing exercises and very short walks',
          '🏊 Swimming with medical supervision',
          '🧘 Chair-based exercises only',
          '💪 Very light stretching with assistance',
          '🚴 Stationary cycling only with medical approval',
          '📈 Focus on daily movement goals',
          '👨‍⚕️ Medical supervision required for all exercise',
          '📱 Track daily activity with medical guidance'
        ];
      default:
        return ['Please consult a healthcare provider for exercise recommendations.'];
    }
  }

  static String getMotivationalMessage(String category) {
    switch (category) {
      case 'Underweight':
        return 'Your journey to a healthy weight starts with small steps. Focus on nourishing your body with healthy foods and building strength. You\'ve got this! 💪';
      case 'Normal weight':
        return 'Great job maintaining a healthy weight! Keep up the good work with balanced nutrition and regular exercise. You\'re doing amazing! 🌟';
      case 'Overweight':
        return 'Every healthy choice you make is a step toward your goals. Small changes add up to big results. You\'re making progress! 🎯';
      case 'Obesity Class I':
        return 'Your health journey is unique and important. Start with small, sustainable changes. Every step forward counts, and you\'re not alone! 🌱';
      case 'Obesity Class II':
        return 'Your health is a priority. Work with healthcare professionals to create a safe, effective plan. You\'re taking important steps toward better health! 💪';
      case 'Obesity Class III':
        return 'Your health journey requires medical support and guidance. You\'re making the right choice by seeking help. Professional care will guide you to better health! 🏥';
      default:
        return 'Your health is important. Take it one day at a time and celebrate every positive choice you make! 💚';
    }
  }
} 