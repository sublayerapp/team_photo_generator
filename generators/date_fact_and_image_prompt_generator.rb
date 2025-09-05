class DateFactAndImagePromptGenerator < Sublayer::Generators::Base
  llm_output_adapter type: :list_of_named_strings,
    name: "fact_options",
    description: "Three different interesting facts and image prompts for the given date",
    item_name: "option",
    attributes: [
      { name: "fact", description: "An interesting fact from the given date" },
      { name: "image_prompt", description: "An image prompt to transform a headshot based on the fact" }
    ]

  def initialize(date:)
    @date = date
  end

  def generate
    super
  end

  def prompt
    <<~PROMPT
      Generate 3 different positive interesting facts and image prompts for a given date.

      Date: #{@date}

      For each option, provide:
      - fact: An interesting and positive fact about this date in the past
      - image_prompt: An image prompt to transform a headshot based on the fact

      Each fact should be something interesting and positive about this date in the past. The image generating AI will be given a headshot of a person and we want it to transform the headshot based on the fact and make it themed around the fact. The image should be a fun and creative transformation of the headshot.

      The historical facts can also be pop culture related - you can lean towards music, comics, cartoons, literature, fiction, TV shows through the 70s, 80s, 90s and early 2000s if you need to.
      Feel free to go with more obscure facts if you can find them, but they should still be positive and interesting. They might also be fictional events, something that happened on a particular date in a particular movie or book.
      Select an unrelated cartoon or artistic style for the headshot as well that's very unrelated to the daily fact that's fun and creative but still integrated.

      The facts will be shown on our team page and the images will be our profile pictures so keep that in mind when generating the fact details and image prompts. Make sure the prompts ensure that the new image is at least somewhat recognizable as the original person (even though we're transforming it to be themed by the daily fact), and integrate the person as much as possible into the theme and scene.

      Provide 3 distinctly different options with varied themes and styles.
    PROMPT
  end
end
