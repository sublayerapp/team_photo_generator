require "yaml"
require "sublayer"

# Load any Actions, Generators, and Agents
Dir[File.join(__dir__, "actions", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "generators", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "agents", "*.rb")].each { |file| require file }
Sublayer.configuration.ai_provider = Sublayer::Providers::Gemini
Sublayer.configuration.ai_model = "gemini-2.5-flash"

images = [
  # Place team photos here
]

# Today's date as Month, day
all_generated_facts = []

loop do
  generated_facts = DateFactAndImagePromptGenerator.new(
    date: Date.today.strftime("%B %d"),
    previous_facts: all_generated_facts.flatten.map(&:fact)
  ).generate

  puts "\nChoose from the following fact and image prompt options for #{Date.today.strftime("%B %d")}:\n\n"

  generated_facts.each_with_index do |option, index|
    puts "#{index + 1}. #{option.fact}"
    puts "   Image style: #{option.image_prompt}"
    puts ""
  end

  puts "4. Generate new facts (different from previous ones)"
  puts ""

  print "Select an option (1-4): "
  choice = gets.chomp.to_i

  if choice == 4
    all_generated_facts << generated_facts
    puts "\nGenerating new facts...\n"
    next
  elsif choice >= 1 && choice <= 3
    @selected_option = generated_facts[choice - 1]
    break
  else
    puts "Invalid selection. Please choose 1, 2, 3, or 4."
    next
  end
end

if @selected_option

  puts "\nYou selected:"
  puts "Fact: #{@selected_option.fact}"
  puts "Image prompt: #{@selected_option.image_prompt}"

  # Loop to allow regeneration
  loop do
    puts "\nGenerating images..."

    # Format: name_m_d_y.jpg (without leading zeros)
    today = Date.today
    date_suffix = "#{today.month}_#{today.day}_#{today.year}"

    images.each do |image_path|
      base_name = File.basename(image_path, ".*")
      output_filename = "#{base_name}_#{date_suffix}.jpg"

      result = GeminiImageGenerationAction.new(
        image_path: image_path,
        prompt: @selected_option.image_prompt,
        output_path: "./output/#{output_filename}",
      ).call

      puts "Generated image saved to #{result[:output_path]}"
    end

    print "\nAccept these images? (y/n): "
    accept = gets.chomp.downcase

    if accept == 'y'
      # Output final markdown
      puts "\n" + "="*60
      puts "\n** #{Date.today.strftime("%B %d, %Y")} - Today in History **"
      puts "\n#{@selected_option.fact}"
      puts "\n** Image Generation Prompt **"
      puts "\n#{@selected_option.image_prompt}"
      puts "\n" + "="*60
      break
    else
      puts "\nRegenerating images with the same prompt..."
    end
  end
else
  puts "Invalid selection. Please run the script again and choose 1, 2, or 3."
end
