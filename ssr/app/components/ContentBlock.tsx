import { ContentBlock as ContentBlockType } from "../../types";

interface ContentBlockProps {
  block: ContentBlockType;
}

export default function ContentBlock({ block }: ContentBlockProps) {
  if (!block.is_visible) {
    return null;
  }

  const getBlockClasses = () => {
    const baseClasses = "w-full";
    const customClasses = block.css_classes ? ` ${block.css_classes}` : "";
    return baseClasses + customClasses;
  };

  const getBlockStyle = () => {
    const style: React.CSSProperties = {};
    if (block.background_color) {
      style.backgroundColor = block.background_color;
    }
    return style;
  };

  const renderContent = () => {
    switch (block.block_type) {
      case "text":
        return (
          <div className="prose max-w-none">
            {block.title && (
              <h3 className="text-2xl font-bold text-gray-900 mb-4">
                {block.title}
              </h3>
            )}
            <div
              className="text-gray-700 leading-relaxed"
              dangerouslySetInnerHTML={{ __html: block.content }}
            />
          </div>
        );

      case "image":
        return (
          <div className="text-center">
            {block.title && (
              <h3 className="text-2xl font-bold text-gray-900 mb-4">
                {block.title}
              </h3>
            )}
            {block.image_url && (
              <img
                src={block.image_url}
                alt={block.image_alt_text || block.title || "Content image"}
                className="mx-auto rounded-lg shadow-md max-w-full h-auto"
              />
            )}
            {block.content && (
              <div
                className="mt-4 text-gray-600"
                dangerouslySetInnerHTML={{ __html: block.content }}
              />
            )}
          </div>
        );

      case "text_image":
        return (
          <div className="flex flex-col lg:flex-row gap-8 items-center">
            <div className="flex-1">
              {block.title && (
                <h3 className="text-2xl font-bold text-gray-900 mb-4">
                  {block.title}
                </h3>
              )}
              <div
                className="prose text-gray-700 leading-relaxed"
                dangerouslySetInnerHTML={{ __html: block.content }}
              />
            </div>
            {block.image_url && (
              <div className="flex-1">
                <img
                  src={block.image_url}
                  alt={block.image_alt_text || block.title || "Content image"}
                  className="rounded-lg shadow-md w-full h-auto"
                />
              </div>
            )}
          </div>
        );

      case "quote":
        return (
          <div className="text-center">
            <blockquote className="text-xl italic text-gray-800 mb-4">
              "{block.content}"
            </blockquote>
            {block.title && (
              <cite className="text-gray-600 font-medium">— {block.title}</cite>
            )}
          </div>
        );

      case "stats":
        return (
          <div className="text-center">
            {block.title && (
              <h3 className="text-2xl font-bold text-gray-900 mb-6">
                {block.title}
              </h3>
            )}
            <div
              className="grid grid-cols-1 md:grid-cols-3 gap-8"
              dangerouslySetInnerHTML={{ __html: block.content }}
            />
          </div>
        );

      case "custom_html":
        return (
          <div>
            {block.title && (
              <h3 className="text-2xl font-bold text-gray-900 mb-4">
                {block.title}
              </h3>
            )}
            <div dangerouslySetInnerHTML={{ __html: block.content }} />
          </div>
        );

      default:
        return (
          <div className="prose max-w-none">
            {block.title && (
              <h3 className="text-2xl font-bold text-gray-900 mb-4">
                {block.title}
              </h3>
            )}
            <div
              className="text-gray-700 leading-relaxed"
              dangerouslySetInnerHTML={{ __html: block.content }}
            />
          </div>
        );
    }
  };

  return (
    <div className={getBlockClasses()} style={getBlockStyle()}>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {renderContent()}
      </div>
    </div>
  );
}
