# Content Management Guide

This guide explains how to manage content in Coalition Builder using the Django admin interface.

## Getting Started

### Accessing the Admin Interface

1. Navigate to `http://localhost:8000/admin/` (or your production domain + `/admin/`)
2. Log in with your superuser credentials
3. You'll see the main admin dashboard with different sections

### Creating Your First Homepage

1. Click on **"Homepage Configurations"** under the **Core** section
2. Click **"Add Homepage Configuration"**
3. Fill out the required fields:
   - **Organization name**: Your organization's name
   - **Tagline**: A brief description or slogan
   - **Hero title**: Main headline for your homepage
   - **About section content**: Description of your mission
   - **Contact email**: Primary contact email address

## Homepage Configuration

### Organization Information

**Organization name**: This appears in the browser title, header, and footer of your site.

**Tagline**: A brief slogan that describes your organization's mission. This appears in the meta description and various locations on the site.

**Contact email**: Primary email address for your organization. This is used for contact forms and appears in the footer.

**Contact phone**: Optional phone number that appears in the footer.

### Hero Section

The hero section is the large banner area at the top of your homepage.

**Hero title**: The main headline visitors see first. Keep it compelling and action-oriented.

**Hero subtitle**: Additional context or call-to-action. This should explain what your organization does or invite visitors to take action.

**Hero background image**: Optional URL to a background image. Use high-quality images (1920x1080 or larger) with good contrast for text readability.

### About Section

**About section title**: Defaults to "About Our Mission" but can be customized.

**About section content**: This is where you explain your organization's mission, goals, and approach. HTML is supported for formatting.

### Call-to-Action (CTA)

**CTA title**: Defaults to "Get Involved" - the title for your main call-to-action section.

**CTA content**: Description encouraging visitors to take action.

**CTA button text**: Text that appears on the action button (e.g., "Learn More", "Join Us", "View Campaigns").

**CTA button URL**: Where the button links to (e.g., `/campaigns/`, `mailto:info@yourorg.org`, external URLs).

### Social Media

Add URLs for your organization's social media profiles:

- Facebook URL
- Twitter/X URL
- Instagram URL
- LinkedIn URL

These create social media icons in the footer.

### Campaign Section

**Campaigns section title**: Title for the section showing your policy campaigns (defaults to "Policy Campaigns").

**Campaigns section subtitle**: Optional description for the campaigns section.

**Show campaigns section**: Toggle to show/hide the entire campaigns section on the homepage.

## Content Blocks

Content blocks allow you to add flexible sections to your homepage beyond the standard layout.

### Adding Content Blocks

1. When editing a homepage configuration, scroll down to the **Content blocks** section
2. Click **"Add another Content block"**
3. Choose a block type and configure the content

### Block Types

**Text Block**: Rich text content with HTML support

- Use for additional information sections
- Supports headings, paragraphs, lists, and basic styling
- Good for mission statements, program descriptions

**Image Block**: Display images with optional captions

- Use for photos, infographics, or visual content
- Include descriptive alt text for accessibility
- Image URL should point to web-accessible images

**Text + Image Block**: Combined text and image layout

- Use for feature highlights or program descriptions
- Balances visual and textual content
- Good for showcasing specific initiatives

**Quote Block**: Highlighted testimonials or quotes

- Use for member testimonials or impactful statements
- Creates visual emphasis with special styling
- Include attribution in the content

**Statistics Block**: Display metrics or achievements

- Use for impact numbers, membership stats, or milestones
- Supports custom HTML for flexible layouts
- Great for demonstrating organizational impact

**Custom HTML Block**: Advanced layouts and custom content

- Use for complex layouts not covered by other types
- Requires HTML knowledge
- Allows maximum flexibility

### Content Block Settings

**Title**: Optional title that appears above the content block.

**Order**: Controls the sequence of blocks on the page. Lower numbers appear first.

**Is visible**: Toggle to show/hide blocks without deleting them.

**CSS classes**: Additional styling classes (requires CSS knowledge).

**Background color**: Hex color code for the block background (e.g., #f0f0f0).

### Content Block Best Practices

1. **Order thoughtfully**: Arrange blocks to tell a story and guide visitors through your message
2. **Use variety**: Mix different block types for visual interest
3. **Keep it focused**: Each block should have a clear purpose
4. **Test visibility**: Use the visibility toggle to test different arrangements
5. **Optimize for mobile**: Consider how content will appear on different screen sizes

## Managing Multiple Organizations

### Single Active Homepage

Only one homepage configuration can be active at a time. This ensures:

- Consistent branding across the site
- No confusion about which content to display
- Clear organizational identity

### Switching Organizations

To switch to a different organization's homepage:

1. Deactivate the current homepage:

   - Edit the current active homepage
   - Uncheck **"Is active"**
   - Save

2. Activate the new homepage:
   - Edit the desired homepage configuration
   - Check **"Is active"**
   - Save

### Environment Variables as Fallbacks

If no active homepage exists, the system falls back to environment variables:

- `ORGANIZATION_NAME`
- `ORG_TAGLINE`
- `CONTACT_EMAIL`

This ensures the site always displays some content.

## Content Guidelines

### Writing Effective Content

**Be Clear and Concise**: Visitors should quickly understand your mission and how they can get involved.

**Use Action-Oriented Language**: Encourage engagement with words like "join", "support", "advocate", "protect".

**Tell Your Story**: Explain why your organization exists and what makes it unique.

**Include Calls-to-Action**: Make it easy for visitors to take the next step.

### SEO Best Practices

**Organization Name**: Should be your official organization name for brand consistency.

**Tagline**: Acts as the meta description - keep it under 160 characters and make it compelling.

**Hero Title**: This often becomes the page title, so make it descriptive and keyword-rich.

**Content Structure**: Use headings and organized content for better search engine understanding.

### Accessibility

**Alt Text**: Always include descriptive alt text for images.

**Heading Structure**: Use proper heading hierarchy in content blocks.

**Color Contrast**: Ensure sufficient contrast between text and background colors.

**Link Text**: Use descriptive text for links, avoid "click here".

## Troubleshooting

### Common Issues

**"Only one homepage configuration can be active" Error**:

- Deactivate the existing homepage before activating a new one
- Check that no other homepage has "Is active" checked

**Content Not Appearing**:

- Verify the homepage configuration is marked as active
- Check that content blocks are marked as visible
- Ensure content blocks have reasonable order values

**Images Not Loading**:

- Verify image URLs are publicly accessible
- Use full URLs including https://
- Check image file formats (JPG, PNG, WebP recommended)

**Styling Issues**:

- CSS classes require corresponding styles in the frontend
- Background colors should use hex format (#ffffff)
- Test changes on different screen sizes

### Getting Help

1. Check the error messages in the Django admin interface
2. Verify your content follows the guidelines in this document
3. Test changes in a development environment first
4. Contact your technical team for complex styling or functionality issues

## Advanced Features

### Custom HTML Content

For advanced users, custom HTML blocks allow complex layouts:

```html
<div class="grid grid-cols-2 gap-6">
  <div>
    <h3 class="text-xl font-bold mb-2">Our Approach</h3>
    <p>We bring together diverse stakeholders...</p>
  </div>
  <div>
    <h3 class="text-xl font-bold mb-2">Our Impact</h3>
    <p>Since 2020, we've successfully...</p>
  </div>
</div>
```

### Statistics Block Examples

```html
<div class="text-center">
  <div class="text-4xl font-bold text-blue-600 mb-2">150+</div>
  <div class="text-gray-600">Member Organizations</div>
</div>
```

### Rich Text Formatting

Most text fields support HTML formatting:

```html
<p>
  This is a paragraph with <strong>bold text</strong> and <em>italic text</em>.
</p>
<ul>
  <li>First bullet point</li>
  <li>Second bullet point</li>
</ul>
```

Remember to test all content changes to ensure they display correctly on both desktop and mobile devices.
