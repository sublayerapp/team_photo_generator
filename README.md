# TeamExample

This is an example script for generating variations of team photos based on a daily historic fact.

## Usage

Add the full paths to your team photos in `team_example.rb` into the images
array.

Make sure your openai api key is set in an environment variable called `OPENAI_API_KEY`.

Run your script:

```
$ ruby team_example.rb
```

## Optional (Gemini)

I didn't have as much success getting Gemini to stick close enough to the
original photo to be recognizable, but it may work better for you. It also may
work better once newer models are released.

If you'd like to use Gemini's image generation api instead:

Set your Gemini api key in an environment variable called `GEMINI_API_KEY`.

Change `OpenAIImageGenerationAction` to `GeminiImageGenerationAction` in the
`team_example.rb` file.

