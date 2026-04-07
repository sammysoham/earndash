import { Body, Controller, Get, Header, Post } from '@nestjs/common';
import { AuthService } from './auth.service';
import { PublicAccountDeletionRequestDto } from './dto/public-account-deletion-request.dto';

@Controller('account-deletion')
export class AccountDeletionController {
  constructor(private readonly authService: AuthService) {}

  @Get()
  @Header('Content-Type', 'text/html; charset=utf-8')
  page() {
    return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>EarnDash Account Deletion</title>
    <style>
      :root {
        color-scheme: dark;
      }
      body {
        margin: 0;
        font-family: Inter, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        background: #07120c;
        color: #e8fff0;
      }
      .wrap {
        max-width: 760px;
        margin: 0 auto;
        padding: 32px 20px 56px;
      }
      .card {
        background: linear-gradient(180deg, #0d1d15, #0a1510);
        border: 1px solid rgba(31, 245, 198, 0.12);
        border-radius: 28px;
        padding: 28px;
        box-shadow: 0 16px 50px rgba(0, 0, 0, 0.25);
      }
      h1 {
        margin: 0 0 12px;
        font-size: 32px;
      }
      p, li {
        color: #b7cdc1;
        line-height: 1.65;
      }
      .eyebrow {
        display: inline-block;
        margin-bottom: 14px;
        padding: 8px 12px;
        border-radius: 999px;
        background: rgba(0, 230, 118, 0.12);
        color: #93ffc6;
        font-weight: 700;
        font-size: 14px;
      }
      form {
        margin-top: 24px;
      }
      label {
        display: block;
        margin-bottom: 8px;
        font-weight: 600;
      }
      input, textarea {
        width: 100%;
        box-sizing: border-box;
        border-radius: 16px;
        border: 1px solid #1e402b;
        background: #0d1712;
        color: #ecfff4;
        padding: 14px 16px;
        margin-bottom: 16px;
        font: inherit;
      }
      button {
        border: 0;
        border-radius: 18px;
        background: #00e676;
        color: #082212;
        font-weight: 800;
        padding: 14px 18px;
        cursor: pointer;
      }
      .note {
        margin-top: 20px;
        padding: 18px;
        border-radius: 20px;
        background: #0b1712;
      }
      ul {
        padding-left: 20px;
      }
    </style>
  </head>
  <body>
    <div class="wrap">
      <div class="card">
        <div class="eyebrow">EarnDash Account Deletion</div>
        <h1>Request deletion of your EarnDash account</h1>
        <p>
          Use this page if you want your EarnDash account closed and queued for deletion review.
          Once requested, account access, rewards, withdrawals, and leaderboard visibility may be restricted immediately.
        </p>
        <ul>
          <li>Enter the same email address used on your EarnDash account.</li>
          <li>Deletion requests may require fraud, payout, or legal review before final removal.</li>
          <li>Certain records may be retained where required for fraud prevention, compliance, disputes, or payment auditing.</li>
        </ul>
        <form method="post" action="/account-deletion/request">
          <label for="email">Account email</label>
          <input id="email" name="email" type="email" required placeholder="you@example.com" />

          <label for="reason">Reason (optional)</label>
          <textarea id="reason" name="reason" rows="5" placeholder="Tell us why you want the account deleted"></textarea>

          <button type="submit">Submit deletion request</button>
        </form>
        <div class="note">
          <strong>Need help instead?</strong>
          <p>
            If you only need support, payout help, or account review, contact EarnDash support rather than deleting the account.
          </p>
        </div>
      </div>
    </div>
  </body>
</html>`;
  }

  @Post('request')
  @Header('Content-Type', 'text/html; charset=utf-8')
  async request(@Body() dto: PublicAccountDeletionRequestDto) {
    await this.authService.requestPublicAccountDeletion(dto);

    return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Request received</title>
    <style>
      body {
        margin: 0;
        font-family: Inter, system-ui, sans-serif;
        background: #07120c;
        color: #ecfff4;
      }
      .wrap {
        max-width: 720px;
        margin: 0 auto;
        padding: 48px 20px;
      }
      .card {
        border-radius: 28px;
        background: #0d1d15;
        border: 1px solid rgba(31, 245, 198, 0.12);
        padding: 28px;
      }
      h1 { margin-top: 0; }
      p { color: #b7cdc1; line-height: 1.65; }
      a {
        color: #8cffc6;
      }
    </style>
  </head>
  <body>
    <div class="wrap">
      <div class="card">
        <h1>Deletion request received</h1>
        <p>
          If an EarnDash account exists for that email address, a deletion request has been recorded for review.
          Access may be restricted while our team completes fraud, payout, and compliance checks.
        </p>
        <p><a href="/account-deletion">Submit another request</a></p>
      </div>
    </div>
  </body>
</html>`;
  }
}
