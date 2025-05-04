class DateFactAndImagePromptGenerator < Sublayer::Generators::Base
  llm_output_adapter type: :named_strings,
    name: "fact_and_prompt",
    description: "An interesting fact and an image prompt",
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
      Generate a positive interesting fact and an image prompt for a given date.

      Date: #{@date}

      This fact should be something interesting and positive about this date in the past, and then for the image prompt
      the image generating ai will be given a headshot of a person and we want it to transform the headshot based on the fact.

      The fact will be shown on our team page and the image will be our profile pictures so keep that in mind when generating the fact details
      and image prompt and make sure the prompt ensures that the new image is at least somewhat recognizable as the original person (even though we're
      transforming it to be themed by the daily fact).
    PROMPT
  end
end
