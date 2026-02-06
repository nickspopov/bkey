import Foundation

enum SentenceBank {
    static let sentences: [String] = [
        "The quick brown fox jumps over the lazy dog.",
        "Pack my box with five dozen liquor jugs.",
        "How vexingly quick daft zebras jump.",
        "The five boxing wizards jump quickly.",
        "Jackdaws love my big sphinx of quartz.",
        "Two driven jocks help fax my big quiz.",
        "The jay, pig, fox, zebra and my wolves quack.",
        "Sympathizing would fix Quaker objectives.",
        "A wizard's job is to vex chumps quickly in fog.",
        "Watch Jeopardy, Alex Trebek's fun TV quiz game.",
        "By Jove, my quick study of lexicography won a prize.",
        "Waxy and quivering, jocks fumble the pizza.",
        "The quick onyx goblin jumps over the lazy dwarf.",
        "Grumpy wizards make a toxic brew for the jovial queen.",
        "All questions asked by five watched experts amaze the judge.",
        "Jack quietly moved up front and seized the big ball of wax.",
        "Few black taxis drive up major roads on quiet hazy nights.",
        "Just keep examining every low bid quoted for zinc etchings.",
        "How quickly daft jumping zebras vex.",
        "Crazy Frederick bought many very exquisite opal jewels.",
        "We promptly judged antique ivory buckles for the next prize.",
        "A large fawn jumped quickly over white zinc boxes.",
        "Six big juicy steaks sizzled in a pan as five workmen left the quarry.",
        "The explorer was frozen in his big kayak just after making queer discoveries.",
        "While making deep excavations we found some quaint bronze jewelry.",
        "Jelly-like above the high wire, six quaking pachyderms kept the climax of the extravaganza in a dazzling state of flux.",
        "The job requires extra pluck and zeal from every young wage earner.",
        "A quick movement of the enemy will jeopardize six gunboats.",
        "We quickly seized the black axle and just saved it from going past him.",
        "The public was amazed to view the quickness and dexterity of the juggler.",
        "Even the smallest keyboard can produce amazing results with practice.",
        "Typing without looking at the keys helps build muscle memory over time.",
        "Consistent daily practice will improve your speed and accuracy.",
        "Focus on accuracy first and speed will naturally follow.",
        "Keep your fingers on the home row and reach for other keys.",
        "Good posture helps prevent fatigue during long typing sessions.",
        "The semicolon and apostrophe are typed with the right pinky finger.",
        "Numbers along the top row require a slight upward reach.",
        "Quick reflexes help when typing complex words and phrases.",
        "Vowels are spread across both hands for balanced typing.",
    ]

    static func generateText(minLength: Int = 500) -> String {
        var shuffled = sentences.shuffled()
        var result = ""
        while result.count < minLength {
            if shuffled.isEmpty {
                shuffled = sentences.shuffled()
            }
            if !result.isEmpty {
                result += " "
            }
            result += shuffled.removeFirst()
        }
        return result
    }
}
