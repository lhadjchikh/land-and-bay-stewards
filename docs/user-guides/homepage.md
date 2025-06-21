# Homepage Management

Coalition Builder provides a flexible, database-driven homepage that can be customized through the Django admin interface. This guide covers how to create and manage your organization's homepage content.

## Overview

The homepage system consists of two main components:

1. **Homepage Configuration** - Core organization information and settings
2. **Content Blocks** - Flexible content sections that can be arranged and customized

## Accessing Homepage Management

1. Log into Django admin at `/admin`
2. Navigate to **Core** → **Homepage Configurations**
3. Click on your existing homepage or create a new one

## Homepage Configuration

### Organization Information

- **Organization Name**: Your organization's full name
- **Tagline**: Brief description or mission statement
- **Contact Email**: Primary contact email (required)
- **Contact Phone**: Optional phone number

### Hero Section

The hero section appears at the top of your homepage:

- **Hero Title**: Main headline (e.g., "Welcome to [Organization]")
- **Hero Subtitle**: Supporting text or call-to-action
- **Hero Background Image**: URL to background image (optional)

### About Section

- **About Section Title**: Heading for your mission/about section
- **About Section Content**: Main content describing your organization
  - Supports HTML formatting
  - Use paragraph tags for proper spacing: `<p>Your content here</p>`

### Call-to-Action (CTA)

- **CTA Title**: Heading for your primary call-to-action
- **CTA Content**: Description of what people can do
- **CTA Button Text**: Text for the action button (e.g., "Join Us")
- **CTA Button URL**: Where the button links (must be full URL: `https://...`)

### Social Media

Add your organization's social media profiles:

- **Facebook URL**
- **Twitter/X URL**
- **Instagram URL**
- **LinkedIn URL**

### Campaigns Section

Control how policy campaigns are displayed:

- **Campaigns Section Title**: Heading for the campaigns area
- **Campaigns Section Subtitle**: Optional description
- **Show Campaigns Section**: Toggle to show/hide campaigns on homepage

### Settings

- **Is Active**: Only one homepage can be active at a time
- **Created At** / **Updated At**: Automatic timestamps

## Content Blocks

Content blocks provide flexible sections that can be added, reordered, and customized.

### Adding Content Blocks

1. In the homepage admin, scroll to **Content Blocks** section
2. Click **Add another Content Block**
3. Configure the block settings

### Content Block Types

#### Text Block

- Standard text content with HTML support
- Good for paragraphs, lists, and formatted text

#### Image Block

- Displays an image with optional caption
- Requires **Image URL** and **Image Alt Text**

#### Text + Image Block

- Combines text content with an image
- Can be arranged side-by-side or stacked

#### Quote Block

- Highlighted quotations or testimonials
- Styled with special formatting

#### Statistics Block

- Display key numbers or metrics
- Use HTML for custom layouts:
  ```html
  <div class="grid grid-cols-3 gap-4 text-center">
    <div>
      <div class="text-3xl font-bold">100+</div>
      <div>Members</div>
    </div>
    <div>
      <div class="text-3xl font-bold">50+</div>
      <div>Campaigns</div>
    </div>
    <div>
      <div class="text-3xl font-bold">25</div>
      <div>States</div>
    </div>
  </div>
  ```

#### Custom HTML Block

- Full HTML content for advanced layouts
- Use with caution - ensure HTML is valid

### Content Block Settings

- **Title**: Optional heading for the block
- **Order**: Controls the sequence (lower numbers appear first)
- **Is Visible**: Toggle to show/hide without deleting
- **CSS Classes**: Optional custom styling classes
- **Background Color**: Hex color code (e.g., `#f0f0f0`)

### Organizing Content Blocks

- **Reorder**: Change the **Order** field (1, 2, 3, etc.)
- **Show/Hide**: Use **Is Visible** checkbox
- **Delete**: Use the delete checkbox and save

## Best Practices

### Content Writing

1. **Keep it concise**: Write clear, scannable content
2. **Use headings**: Break up long content with subheadings
3. **Include calls-to-action**: Guide visitors to take action
4. **Update regularly**: Keep information current

### Images

1. **Use proper URLs**: Always use full URLs starting with `https://`
2. **Add alt text**: Describe images for accessibility
3. **Optimize size**: Use appropriately sized images to avoid slow loading
4. **Consistent style**: Maintain visual consistency across images

### Content Structure

1. **Logical flow**: Arrange content blocks in a natural reading order
2. **Visual hierarchy**: Use different block types to create visual interest
3. **Call-to-action placement**: Position important actions prominently
4. **Mobile consideration**: Keep layouts simple for mobile viewing

## Examples

### Basic Organization Homepage

1. **Hero Section**: Welcome message with organization name
2. **Text Block**: Mission statement and goals
3. **Image Block**: Photo of your work or team
4. **Statistics Block**: Key achievements or impact numbers
5. **Text Block**: How to get involved
6. **Campaigns Section**: Current policy priorities

### Advocacy Campaign Homepage

1. **Hero Section**: Campaign-specific messaging
2. **Text + Image Block**: Problem description with relevant image
3. **Quote Block**: Testimonial from affected person
4. **Statistics Block**: Problem scope and impact
5. **Text Block**: Proposed solution
6. **Custom HTML Block**: Embedded petition or action form

## Troubleshooting

### Common Issues

**Homepage not updating**

- Check that **Is Active** is enabled
- Clear browser cache
- Verify content blocks are marked **Is Visible**

**Images not displaying**

- Ensure image URLs start with `https://`
- Check that images are publicly accessible
- Verify URLs are correct (test in new browser tab)

**Formatting problems**

- Use proper HTML tags: `<p>`, `<h2>`, `<ul>`, `<li>`
- Close all HTML tags properly
- Avoid complex CSS unless you're familiar with the styling

**Button links not working**

- Use full URLs: `https://example.com/page`
- Test links in a new browser tab
- Check for typos in URLs

### Getting Help

- Check the [Troubleshooting Guide](../admin/troubleshooting.md)
- Review [API Documentation](../api/index.md) for technical details
- Consult [Development Setup](../development/setup.md) for local testing
