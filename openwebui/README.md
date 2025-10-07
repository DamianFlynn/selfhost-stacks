# OpenWebUI AI Stack

A comprehensive self-hosted AI platform featuring chat interfaces, document processing, search capabilities, and tool integrations with AMD GPU acceleration.

## 🌟 Stack Overview

This stack provides a complete AI-powered environment with the following components:

- **OpenWebUI** - Modern AI chat interface with RAG capabilities
- **Ollama** - Local LLM server with AMD GPU acceleration
- **SearXNG** - Privacy-focused search engine
- **Docling** - Advanced document processing
- **MCP Server** - Model Context Protocol for tool integrations
- **PostgreSQL** - Database with vector embeddings (pgvector)
- **Redis Stack** - Caching and session management
- **Apache Tika** - Document parsing and metadata extraction
- **EdgeTTS** - Text-to-speech synthesis

## 🌐 Public Web Interfaces

### Primary Services
- **AI Chat Interface**: `https://chat.deercrest.info`
  - Main OpenWebUI interface for AI conversations
  - Document upload and RAG (Retrieval-Augmented Generation)
  - Web search integration
  - Voice synthesis capabilities

- **Privacy Search Engine**: `https://search.deercrest.info`
  - SearXNG privacy-focused search
  - Can be set as default browser search engine
  - Aggregates results without tracking

### API & Integration Services
- **Ollama AI Models**: `https://ollama.deercrest.info`
  - RESTful API for AI model management
  - Compatible with Home Assistant and other integrations
  - Direct model access for custom applications

- **Document Processing**: `https://docling.deercrest.info`
  - Web UI available at `/ui`
  - API documentation at `/docs`
  - Converts PDFs, Word docs, and more to structured formats

- **MCP Tools Server**: `https://mcp.deercrest.info`
  - Model Context Protocol server
  - Compatible with VS Code MCP extensions
  - Extensible tool integration platform

## 🔧 Hardware Requirements

### Minimum Requirements
- **CPU**: AMD Ryzen with integrated graphics (tested on Ryzen AI 9 HX PRO 370)
- **GPU**: AMD Radeon with ROCm support (tested on Radeon 890M)
- **RAM**: 16GB minimum (32GB recommended)
- **Storage**: 50GB for base installation + model storage

### Optimal Configuration
- **GPU**: AMD RDNA2/RDNA3 with 8GB+ VRAM
- **RAM**: 64GB for large model support
- **Storage**: NVMe SSD for model storage and vector database

## 🚀 Quick Start

### Prerequisites
1. Docker and Docker Compose installed
2. Traefik reverse proxy with SSL certificates
3. AMD GPU drivers and ROCm support
4. DNS records pointing to your server:
   - `chat.deercrest.info`
   - `search.deercrest.info`
   - `ollama.deercrest.info`
   - `docling.deercrest.info`
   - `mcp.deercrest.info`

### Deployment
```bash
# Clone the repository
git clone <repository-url>
cd selfhost-stacks/openwebui

# Create data directories
sudo mkdir -p /mnt/fast/appdata/llm-ai/{postgres,ollama,searxng,open-webui}
sudo chown -R $USER:$USER /mnt/fast/appdata/llm-ai

# Start the stack
docker compose up -d
```

### Initial Setup
1. **Download AI Models**:
   ```bash
   # Install a model via API
   curl https://ollama.deercrest.info/api/pull -d '{"name":"llama3.2"}'
   
   # Or use the web interface at https://ollama.deercrest.info
   ```

2. **Configure Search Engine**:
   - Add `https://search.deercrest.info/search?q=%s` as a custom search engine in your browser

3. **Access the Chat Interface**:
   - Visit `https://chat.deercrest.info`
   - Create an account and start chatting

## 🔌 Integration Examples

### Home Assistant
Add to your `configuration.yaml`:
```yaml
conversation:
  - platform: ollama
    url: "https://ollama.deercrest.info"
    model: "llama3.2"
    prompt: "You are a helpful assistant for smart home automation."
```

### VS Code MCP Integration
1. Install an MCP-compatible extension
2. Configure MCP server URL: `https://mcp.deercrest.info`
3. Access time, database queries, and other tools directly in VS Code

### Browser Search Engine
- **URL**: `https://search.deercrest.info/search?q=%s`
- **Name**: "DeercrestSearch"
- **Keyword**: "ds"

### API Usage Examples
```bash
# Chat with AI model
curl -X POST https://ollama.deercrest.info/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model":"llama3.2","prompt":"Hello, how are you?"}'

# Process a document
curl -X POST https://docling.deercrest.info/v1/convert \
  -F "file=@document.pdf" \
  -F "output_format=markdown"

# Get current time via MCP
curl -X POST https://mcp.deercrest.info/time/get_current_time \
  -H "Content-Type: application/json" \
  -d '{"timezone": "Europe/Dublin"}'
```

## 🧠 AI Models

### Recommended Models
- **Small/Fast**: `llama3.2:3b` (3GB VRAM)
- **Balanced**: `llama3.2:8b` (8GB VRAM)
- **Large/Capable**: `llama3.1:70b` (requires CPU fallback)
- **Embedding**: `nomic-embed-text` (for RAG)

### Model Management
```bash
# List available models
curl https://ollama.deercrest.info/api/tags

# Pull a specific model
curl https://ollama.deercrest.info/api/pull -d '{"name":"model_name"}'

# Remove a model
curl -X DELETE https://ollama.deercrest.info/api/delete -d '{"name":"model_name"}'
```

## 📚 Document Processing

### Supported Formats
- **Documents**: PDF, DOCX, PPTX, XLSX
- **Images**: PNG, JPG (with OCR)
- **Archives**: ZIP, TAR
- **Code**: Most programming languages
- **Markup**: HTML, XML, Markdown

### Processing Pipeline
1. **Upload** → Document uploaded to OpenWebUI
2. **Parse** → Tika extracts text and metadata
3. **Structure** → Docling converts to structured format
4. **Embed** → Text converted to vector embeddings
5. **Store** → Saved in PostgreSQL with pgvector
6. **Query** → Available for RAG in conversations

## 🔍 Search Capabilities

### SearXNG Features
- **Privacy**: No tracking or data collection
- **Aggregation**: Results from multiple search engines
- **Customization**: Configurable engines and preferences
- **API Access**: RESTful API for programmatic access

### OpenWebUI Search Integration
- **Web Search**: Real-time search during conversations
- **RAG Enhancement**: Search results enhance AI responses
- **Document Search**: Search within uploaded documents
- **Vector Search**: Semantic similarity search

## 🛠️ Advanced Configuration

### MCP Server Extension
Edit `/mnt/fast/appdata/llm-ai/open-webui/conf/mcp/config.json`:
```json
{
  "mcpServers": {
    "time": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-time"]
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "POSTGRES_CONNECTION_STRING": "postgresql://owui-user:171d29d40f07946b@ai-postgress/owui"
      }
    }
  }
}
```

### Custom Search Engines
Add to SearXNG configuration in `/mnt/fast/appdata/llm-ai/searxng/settings.yml`:
```yaml
engines:
  - name: custom_api
    engine: json_engine
    search_url: https://api.example.com/search
    results_xpath: //results/item
```

### Environment Customization
Key environment variables in the compose file:
- `OLLAMA_CONTEXT_LENGTH`: Token context window
- `RAG_EMBEDDING_MODEL`: Model for document embeddings
- `WEBSOCKET_REDIS_URL`: Real-time communication backend
- `SEARXNG_BASE_URL`: Public URL for search integration

## 📊 Monitoring & Maintenance

### Health Checks
All services include health checks:
```bash
# Check service status
docker compose ps

# View service logs
docker compose logs -f openwebui
docker compose logs -f ai-ollama
```

### Performance Monitoring
- **GPU Usage**: `watch -n 1 'rocm-smi'`
- **Memory**: `docker stats`
- **Database**: Connect to PostgreSQL and check `pg_stat_activity`
- **Redis**: Use RedisInsight at Redis console

### Backup Strategy
```bash
# Database backup
docker compose exec ai-postgress pg_dump -U owui-user owui > backup.sql

# Volume backup
tar -czf openwebui-backup.tar.gz /mnt/fast/appdata/llm-ai/
```

## 🔒 Security Considerations

### Network Security
- Services isolated in Docker networks
- Only required services exposed via Traefik
- SSL/TLS termination at reverse proxy

### Data Privacy
- No external API calls (fully self-hosted)
- Local model processing
- Encrypted database connections
- No telemetry or tracking

### Access Control
- Traefik can be configured with authentication
- OpenWebUI has built-in user management
- API access can be restricted by IP/network

## 🐛 Troubleshooting

### Common Issues

**AMD GPU Not Detected**:
```bash
# Check ROCm installation
rocm-smi
# Verify device access
ls -la /dev/kfd /dev/dri
```

**Models Not Loading**:
```bash
# Check Ollama logs
docker compose logs ai-ollama
# Verify model files
docker compose exec ai-ollama ls -la /root/.ollama/models
```

**Search Not Working**:
```bash
# Check SearXNG logs
docker compose logs ai-searxng
# Verify Redis connection
docker compose exec ai-redis redis-cli ping
```

**SearXNG Engine Errors** (e.g., Pinterest KeyError):
- These are **normal and non-critical**
- Individual search engines may fail due to API changes
- SearXNG continues working with other engines
- To disable problematic engines, edit `/mnt/fast/appdata/llm-ai/searxng/settings.yml`:
```yaml
engines:
  - name: pinterest
    disabled: true
```

**Document Processing Fails**:
```bash
# Check Tika service
curl http://localhost:9998/tika
# Check Docling service
curl https://docling.deercrest.info/health
```

### Performance Tuning

**Memory Optimization**:
- Adjust `OLLAMA_CONTEXT_LENGTH` based on available RAM
- Use smaller models for faster responses
- Enable model unloading with `OLLAMA_KEEP_ALIVE`

**GPU Optimization**:
- Set `OLLAMA_NUM_GPU=1` for single GPU systems
- Adjust `HSA_OVERRIDE_GFX_VERSION` for compatibility
- Monitor VRAM usage with `rocm-smi`

## 📝 License

This configuration is provided under the MIT License. Individual components maintain their respective licenses.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes
4. Submit a pull request

## 📞 Support

For issues and questions:
- Check the troubleshooting section
- Review component documentation
- Open an issue in the repository

---

**Stack Version**: 1.0.0  
**Last Updated**: October 2025  
**Tested On**: AMD Ryzen AI 9 HX PRO 370 with Radeon 890M
