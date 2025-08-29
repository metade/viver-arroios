---
layout: map
---

<div class="map-overlay bg-white bg-opacity-75 rounded-3 p-3 shadow">
  <h1 class="h4 fw-semibold text-dark mb-2">{{ site.title }}</h1>
  <p class="text-muted mb-0 small">{{ site.description }}</p>
  <button type="button" class="btn btn-primary btn-sm mt-3 fw-medium shadow-sm" id="moreInfoBtn">
    <i class="bi bi-info-circle me-2"></i>Mais Informações
  </button>
</div>

<!-- Side Panel Content Templates -->
<div class="d-none">
  <!-- Default content -->
  <div id="defaultContent" class="panel-content" data-content-type="default" data-panel-title="Detalhes da Proposta">
    <div class="text-center py-5">
      <i class="bi bi-geo-alt text-muted" style="font-size: 3rem;"></i>
      <p class="text-muted mt-3 mb-0">Clique num marcador para ver os detalhes.</p>
    </div>
  </div>

  <!-- General info content template -->
  <div id="generalInfoContent" class="panel-content" data-content-type="general" data-panel-title="Informações Gerais">
    <div class="mb-3 pb-2 border-bottom">
      <div class="fw-semibold text-body-secondary small text-uppercase mb-1">Coligação Viver Arroios</div>
      <p class="text-dark">
          Arroios é uma freguesia única em Lisboa. Em pleno coração da cidade, concentra-se o quilómetro quadrado mais densamente povoado de Portugal (CENSO 2021), onde a pressão sobre o espaço público, a habitação e a mobilidade se sente todos os dias.
          ...
      </p>
    </div>
    <div class="mb-3 pb-2 border-bottom">
      <div class="fw-semibold text-body-secondary small text-uppercase mb-1">Como Usar</div>
      <div class="text-dark">
        <ul class="mb-0">
          <li>Clique nos pontos azuis para ver detalhes das propostas</li>
          <li>Use os controlos de zoom (+/-) para navegar</li>
          <li>Use o botão de localização para centrar no seu local</li>
        </ul>
      </div>
    </div>
    <div class="mb-0">
      <div class="fw-semibold text-body-secondary small text-uppercase mb-1">Navegação</div>
      <div class="text-dark">Arraste o mapa para explorar diferentes áreas do bairro de Arroios.</div>
    </div>
  </div>

  <!-- Marker details content container -->
  <div id="markerContent" class="panel-content" data-content-type="marker" data-panel-title="Detalhes da Proposta">
    <!-- This will be populated dynamically by JavaScript -->
  </div>
</div>
