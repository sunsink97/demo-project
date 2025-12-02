## Serverless Demo

AWS Infra DEMO. This GitHub repository is a place to showcase my experience working in infrastructure so far. Below are some of the projects that reflect what I've learned in the past few years.

---

### Serverless architecture

Initial demo project. The idea is to learn how to use GitHub Actions and familiarize myself with the feature.  
The application is just a simple website interface that has a chat box, waiting for user input. When the send button is pressed, the message will be sent to GROQ AI.  
Once the AI returns a reply, it will then be sent back to the frontend. The application is simple and designed to save cost for most of its infrastructure design choices.

---

#### Components Used

| Component | Purpose |
|---------|---------|
| **S3** | Hosts the static website (HTML/CSS/JS). Public access blocked by default, only accessible via CloudFront using bucket policy. |
| **CloudFront + OAC** | Global CDN caching for performance. OAC (Origin Access Control) ensures secure S3 access without exposing the bucket publicly. |
| **Lambda** | Backend compute — receives user input, forwards it to GROQ AI, and returns the response. |
| **API Gateway** | Public interface between frontend and Lambda. Routes chat requests securely and efficiently. |

---

#### Some notable choices

- `price_class = "PriceClass_100"` : Used on CloudFront to reduce cost as much as possible while still using CloudFront for this simple demo project.  
- `automate terraform plan on push` : Learning CI/CD functionality on GitHub Actions. The YAML is designed for testing convenience so that each time code is pushed to a branch, GitHub Actions will execute Terraform plan and apply.  
  Ideally in a real production repo, Terraform apply via GitHub Actions should only be triggered when a pull request is merged into main.
- `using S3 as "Terraform backend"` : Manually created an S3 bucket with the purpose of storing Terraform state. This Terraform state is then used by GitHub Actions and also from local development so both can share a single state file across multiple devices.
- `API Gateway HTTP API (v2)` : nice for simple demo. cheaper than REST version

#### Note to self
- no custom domain, website still use cloudfront id to reach.
- maybe use bootstrapping method to make initial s3 and dynamo db for s3 backend for storing tf state

---
