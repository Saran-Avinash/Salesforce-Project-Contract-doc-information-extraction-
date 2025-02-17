public class DocumentAIResponse {
    public Document document;

    public class Document {
        public List<Entity> entities;
    }

    public class Entity {
        public TextAnchor textAnchor;
        public String type;
        public String mentionText;
        public Double confidence;
        public PageAnchor pageAnchor;
        public String id;
    }

    public class TextAnchor {
        public List<TextSegment> textSegments;
    }

    public class TextSegment {
        public String startIndex;
        public String endIndex;
    }

    public class PageAnchor {
        public List<PageRef> pageRefs;
    }

    public class PageRef {
        public BoundingPoly boundingPoly;
    }

    public class BoundingPoly {
        public List<NormalizedVertex> normalizedVertices;
    }

    public class NormalizedVertex {
        public Double x;
        public Double y;
    }
}
