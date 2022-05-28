from urllib import response
from flask import Flask
from flask import request
from flask import jsonify
import openai
app = Flask(__name__)

openai.api_key = "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"

@app.route("/api", methods=['GET'])
def api():
    d = {}
    d['Query'] = str(request.args['Query'])
    response = openai.Completion.create(
        engine="code-davinci-002",
        prompt=d['Query'],
        temperature=0,
        max_tokens=128,
        top_p=1.0,
        frequency_penalty=0.0,
        presence_penalty=0.0,
        stop=["END"]
    )
    return jsonify(response)

if __name__ == "__main__":
    app.run()
