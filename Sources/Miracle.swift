import ArgumentParser

@main
struct Miracle: ParsableCommand {
    @Argument var gitProfileName: String
    @Argument var gitEmail: String

    static let configuration = CommandConfiguration(
        abstract: "A Swift command-line tool for setting up the developer tools and themes Fury's way."
    )

    mutating func run() throws {
        // 1. Extract only text contents from the file
        // let plainText = try Readometer.getFileContents(from: inputFile)

        // 2. Calculate the estimated reading time in minutes..
        // let wordCount = Readometer.wordCount(from: plainText)
        // let avgReadingSpeed = 200
        // let readingTime = Double(wordCount) / Double(avgReadingSpeed)

        // 3. print the estimated reading time..
//        print("✨✨✨\nEstimated reading time: [readingTime] minutes\n✨✨✨")
        print("arg1 = \(gitProfileName)")
        print("arg2 = \(gitEmail)")
    }
}
