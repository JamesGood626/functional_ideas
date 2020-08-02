const express = require("express");
const app = express();

let tries = 0;

app.get("/", function (req, res) {
  if (tries < 3) {
    console.log("in if: ", tries);
    tries += 1;
    res.status(500).send({ error: "Oops.. Something went wrong" });
  } else {
    console.log("in else");
    res.send({ message: "Twas a success!" });
  }
});

app.listen(3000, () => {
  console.log("listening on port 3000");
});
